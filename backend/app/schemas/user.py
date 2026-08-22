from pydantic import BaseModel, Field
from datetime import datetime


class UserCreate(BaseModel):
    phone: str = Field(..., pattern=r"^1[3-9]\d{9}$")
    password: str = Field(..., min_length=6, max_length=20)
    nickname: str | None = "梦友"


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: int
    phone: str | None
    nickname: str
    avatar: str | None
    created_at: datetime

    class Config:
        from_attributes = True
