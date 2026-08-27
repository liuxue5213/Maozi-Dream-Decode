from datetime import datetime, date
from sqlalchemy import Integer, Text, String, DateTime, Date, ForeignKey, func, JSON, SmallInteger
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Dream(Base):
    __tablename__ = "dreams"

    id: Mapped[int] = mapped_column(Integer, primary_key=True )
    user_id: Mapped[int] = mapped_column( ForeignKey("users.id", ondelete="CASCADE"), index=True)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    emotion_tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    scene_tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    character_tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    sleep_quality: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    dream_date: Mapped[date] = mapped_column(Date, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # 关系
    user: Mapped["User"] = relationship(back_populates="dreams")
    interpretations: Mapped[list["Interpretation"]] = relationship(back_populates="dream", cascade="all, delete-orphan")
