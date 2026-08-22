from fastapi import APIRouter
from app.api import auth, dreams, interpretations, encyclopedia

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router, prefix="/auth", tags=["认证"])
api_router.include_router(dreams.router, prefix="/dreams", tags=["梦境"])
api_router.include_router(interpretations.router, prefix="/interpretations", tags=["解析"])
api_router.include_router(encyclopedia.router, prefix="/encyclopedia", tags=["百科"])
