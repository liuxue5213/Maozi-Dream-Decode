from datetime import datetime
from sqlalchemy import BigInteger, String, DateTime, ForeignKey, func, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Interpretation(Base):
    __tablename__ = "interpretations"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    dream_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("dreams.id", ondelete="CASCADE"), index=True)
    result_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    model_version: Mapped[str] = mapped_column(String(50), default="qwen-plus")
    engine_type: Mapped[str] = mapped_column(String(20), default="ai")  # ai / traditional / psychology
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # 关系
    dream: Mapped["Dream"] = relationship(back_populates="interpretations")
