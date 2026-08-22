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
    return [DreamListResponse.model_validate(d) for d in dreams]


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
    
    result = await interpret_dream(
        content=dream.content,
        emotion_tags=dream.emotion_tags,
        scene_tags=dream.scene_tags,
    )
    
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
        async for chunk in interpret_dream_stream(
            content=dream.content,
            emotion_tags=dream.emotion_tags,
            scene_tags=dream.scene_tags,
        ):
            yield f"data: {chunk}\n\n"
    
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
    
    result = await interpret_dream(
        content=dream.content,
        emotion_tags=dream.emotion_tags,
        scene_tags=dream.scene_tags,
    )
    
    interpretation = Interpretation(
        dream_id=dream.id,
        result_json=result,
        engine_type="ai",
    )
    db.add(interpretation)
    db.commit()
    db.refresh(interpretation)
    
    return InterpretationResponse.model_validate(interpretation)
