from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path
from app.core.config import settings
from app.api import api_router
from app.core.database import engine, Base

# 创建数据库表（开发环境用，生产环境建议用 Alembic 迁移）
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="梦的解析 API",
    description="梦境记录与 AI 解析服务",
    version="1.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 路由
app.include_router(api_router)

# 托管 Web 静态文件
web_dir = Path(__file__).parent / "web"
if web_dir.exists():
    app.mount("/web", StaticFiles(directory=str(web_dir)), name="web")


@app.get("/")
def serve_web():
    """首页返回 Web 前端"""
    index_file = web_dir / "index.html"
    if index_file.exists():
        return FileResponse(str(index_file))
    return {"message": "梦语 API 服务运行中", "docs": "/docs", "version": "1.0.0"}


@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "1.0.0"}
