import json

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.dream import Dream
from app.models.interpretation import Interpretation
from app.schemas.dream import DreamCreate, DreamResponse, DreamListResponse
from app.schemas.interpretation import InterpretationResponse, InterpretationCreate
from app.services.bailian import interpret_dream, interpret_dream_stream

router = APIRouter()


async def generate_interpretation(dream: Dream, follow_up_question: str | None = None) -> dict:
    """Translate provider failures into a safe, client-readable API response."""
    try:
        return await interpret_dream(
            content=dream.content,
            emotion_tags=dream.emotion_tags,
            scene_tags=dream.scene_tags,
            character_tags=dream.character_tags,
            sleep_quality=dream.sleep_quality,
            follow_up_question=follow_up_question,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.post("", response_model=DreamResponse)
def create_dream(
    req: DreamCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """创建梦境记录"""
    dream = Dream(
        user_id=current_user.id,
        content=req.content,
        emotion_tags=req.emotion_tags,
        scene_tags=req.scene_tags,
        character_tags=req.character_tags,
        sleep_quality=req.sleep_quality,
        dream_date=req.dream_date,
    )
    db.add(dream)
    db.commit()
    db.refresh(dream)
    return DreamResponse.model_validate(dream)


@router.get("", response_model=list[DreamListResponse])
def list_dreams(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取梦境列表"""
    offset = (page - 1) * page_size
    dreams = (
        db.query(Dream)
        .filter(Dream.user_id == current_user.id)
        .order_by(Dream.created_at.desc())
        .offset(offset)
        .limit(page_size)
        .all()
    )
    # 查出本页中已有解析结果的梦境 id，避免 schema 默认值导致 has_interpretation 恒为 False
    dream_ids = [d.id for d in dreams]
    interpreted_ids: set[int] = set()
    if dream_ids:
        interpreted_ids = {
            row[0]
            for row in db.query(Interpretation.dream_id)
            .filter(Interpretation.dream_id.in_(dream_ids))
            .distinct()
            .all()
        }
    return [
        DreamListResponse(
            id=d.id,
            content=d.content,
            emotion_tags=d.emotion_tags,
            dream_date=d.dream_date,
            created_at=d.created_at,
            has_interpretation=d.id in interpreted_ids,
        )
        for d in dreams
    ]


@router.get("/{dream_id}", response_model=DreamResponse)
def get_dream(
    dream_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取单个梦境详情"""
    dream = db.query(Dream).filter(Dream.id == dream_id, Dream.user_id == current_user.id).first()
    if not dream:
        raise HTTPException(status_code=404, detail="梦境记录不存在")
    return DreamResponse.model_validate(dream)


@router.delete("/{dream_id}")
def delete_dream(
    dream_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """删除梦境记录"""
    dream = db.query(Dream).filter(Dream.id == dream_id, Dream.user_id == current_user.id).first()
    if not dream:
        raise HTTPException(status_code=404, detail="梦境记录不存在")
    db.delete(dream)
    db.commit()
    return {"message": "删除成功"}


# ===== AI 解析相关路由 =====

@router.get("/{dream_id}/interpretations", response_model=list[InterpretationResponse])
def list_interpretations(
    dream_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取梦境的所有解析结果"""
    dream = db.query(Dream).filter(Dream.id == dream_id, Dream.user_id == current_user.id).first()
    if not dream:
        raise HTTPException(status_code=404, detail="梦境记录不存在")
    
    interpretations = (
        db.query(Interpretation)
        .filter(Interpretation.dream_id == dream_id)
        .order_by(Interpretation.created_at.desc())
        .all()
    )
    return [InterpretationResponse.model_validate(i) for i in interpretations]


@router.post("/{dream_id}/interpretations", response_model=InterpretationResponse)
async def create_interpretation(
    dream_id: int,
    req: InterpretationCreate | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """创建梦境解析（调用百炼 AI）"""
    dream = db.query(Dream).filter(Dream.id == dream_id, Dream.user_id == current_user.id).first()
    if not dream:
        raise HTTPException(status_code=404, detail="梦境记录不存在")
    
    result = await generate_interpretation(dream, req.follow_up_question if req else None)
    
    interpretation = Interpretation(
        dream_id=dream.id,
        result_json=result,
        engine_type="ai",
    )
    db.add(interpretation)
    db.commit()
    db.refresh(interpretation)
    
    return InterpretationResponse.model_validate(interpretation)


@router.post("/{dream_id}/interpretations/stream")
async def create_interpretation_stream(
    dream_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """流式创建梦境解析（打字机效果）"""
    dream = db.query(Dream).filter(Dream.id == dream_id, Dream.user_id == current_user.id).first()
    if not dream:
        raise HTTPException(status_code=404, detail="梦境记录不存在")
    
    async def generate():
        accumulated: list[str] = []
        completed = False
        try:
            async for chunk in interpret_dream_stream(
                content=dream.content,
                emotion_tags=dream.emotion_tags,
                scene_tags=dream.scene_tags,
                character_tags=dream.character_tags,
                sleep_quality=dream.sleep_quality,
            ):
                # 上游 chunk 为 OpenAI 兼容的 JSON 行，解析出增量文本再下发
                try:
                    chunk_json = json.loads(chunk)
                except json.JSONDecodeError:
                    continue
                if chunk_json.get("error"):
                    yield f"data: {json.dumps({'error': chunk_json['error']}, ensure_ascii=False)}\n\n"
                    return
                choices = chunk_json.get("choices") or []
                if not choices:
                    continue
                delta = (choices[0].get("delta") or {}).get("content")
                if delta:
                    accumulated.append(delta)
                    yield f"data: {json.dumps({'content': delta}, ensure_ascii=False)}\n\n"
            completed = True
        finally:
            full_text = "".join(accumulated).strip()
            # 只保存完整跑完的结果，客户端中途断开时不落库截断文本
            if completed and full_text:
                db.add(
                    Interpretation(
                        dream_id=dream.id,
                        result_json={"content": full_text},
                        engine_type="ai",
                    )
                )
                db.commit()
        yield f"data: {json.dumps({'done': True}, ensure_ascii=False)}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@router.post("/{dream_id}/interpretations/regenerate", response_model=InterpretationResponse)
async def regenerate_interpretation(
    dream_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """重新生成解析"""
    dream = db.query(Dream).filter(Dream.id == dream_id, Dream.user_id == current_user.id).first()
    if not dream:
        raise HTTPException(status_code=404, detail="梦境记录不存在")
    
    result = await generate_interpretation(dream)
    
    interpretation = Interpretation(
        dream_id=dream.id,
        result_json=result,
        engine_type="ai",
    )
    db.add(interpretation)
    db.commit()
    db.refresh(interpretation)
    
    return InterpretationResponse.model_validate(interpretation)
