from pydantic import BaseModel
from datetime import datetime


class EncyclopediaItemResponse(BaseModel):
    id: int
    title: str
    category: str
    tags: list | None
    traditional_meaning: str | None
    psychology_meaning: str | None
    culture_meaning: str | None
    advice: str | None
    source: str | None

    class Config:
        from_attributes = True


class EncyclopediaSearchResponse(BaseModel):
    total: int
    items: list[EncyclopediaItemResponse]


class EncyclopediaCategoryResponse(BaseModel):
    category: str
    count: int
