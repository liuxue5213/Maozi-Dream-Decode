from pydantic import BaseModel, Field
from datetime import datetime, date


class DreamCreate(BaseModel):
    content: str = Field(..., min_length=5, max_length=5000)
    emotion_tags: list[str] | None = None
    scene_tags: list[str] | None = None
    character_tags: list[str] | None = None
    sleep_quality: int | None = Field(None, ge=1, le=5)
    dream_date: date


class DreamResponse(BaseModel):
    id: int
    user_id: int
    content: str
    emotion_tags: list | None
    scene_tags: list | None
    character_tags: list | None
    sleep_quality: int | None
    dream_date: date
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DreamListResponse(BaseModel):
    id: int
    content: str
    emotion_tags: list | None
    dream_date: date
    created_at: datetime
    has_interpretation: bool = False

    class Config:
        from_attributes = True
