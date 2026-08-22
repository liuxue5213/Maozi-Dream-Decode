from pydantic import BaseModel
from datetime import datetime


class InterpretationSymbol(BaseModel):
    element: str
    traditional_meaning: str | None = None
    psychology_meaning: str | None = None
    culture_meaning: str | None = None


class InterpretationResult(BaseModel):
    """兼容结构化和 Markdown 两种格式"""
    # Markdown 全文（新格式）
    content: str | None = None
    # 结构化字段（旧格式兼容）
    summary: str | None = None
    symbols: list[InterpretationSymbol] | None = []
    psychology_analysis: str | None = None
    traditional_meaning: str | None = None
    reality_connection: str | None = None
    suggestions: list[str] | None = []
    disclaimer: str = "本解析仅供参考，不构成医疗建议"


class InterpretationResponse(BaseModel):
    id: int
    dream_id: int
    result_json: InterpretationResult | str | None = None
    model_version: str
    engine_type: str
    created_at: datetime

    class Config:
        from_attributes = True


class InterpretationCreate(BaseModel):
    """触发解析（dream_id 在路径中传入，body 留空或扩展追问）"""
    follow_up_question: str | None = None
