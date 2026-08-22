from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.dream import Dream
from app.models.interpretation import Interpretation
from app.schemas.interpretation import InterpretationResponse

router = APIRouter()


@router.get("/{interpretation_id}", response_model=InterpretationResponse)
def get_interpretation(
    interpretation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取单个解析结果"""
    interpretation = (
        db.query(Interpretation)
        .join(Dream, Interpretation.dream_id == Dream.id)
        .filter(Interpretation.id == interpretation_id, Dream.user_id == current_user.id)
        .first()
    )
    if not interpretation:
        raise HTTPException(status_code=404, detail="解析结果不存在")
    return InterpretationResponse.model_validate(interpretation)
