from datetime import datetime
from sqlalchemy import BigInteger, String, Text, DateTime, func, JSON, SmallInteger
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class EncyclopediaItem(Base):
    __tablename__ = "encyclopedia_items"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    category: Mapped[str] = mapped_column(String(50), index=True)  # 动物/自然/身体/场景/事件/颜色
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    traditional_meaning: Mapped[str | None] = mapped_column(Text, nullable=True)
    psychology_meaning: Mapped[str | None] = mapped_column(Text, nullable=True)
    culture_meaning: Mapped[str | None] = mapped_column(Text, nullable=True)
    advice: Mapped[str | None] = mapped_column(Text, nullable=True)
    source: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[int] = mapped_column(SmallInteger, default=1)  # 0草稿 1已发布 2下架
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
