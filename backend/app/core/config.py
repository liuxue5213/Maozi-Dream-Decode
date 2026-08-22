from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # 数据库
    database_url: str = "postgresql://postgres:password@localhost:5432/dream_app"
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # JWT
    secret_key: str = "change-this-secret"
    access_token_expire_days: int = 30
    
    # 阿里云百炼（自定义端点）
    dashscope_api_key: str = ""
    dashscope_model: str = "qwen-plus"
    dashscope_base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    dashscope_enable_thinking: bool = False
    
    # CORS
    allowed_origins: str = "http://localhost:3000"
    
    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]
    
    class Config:
        env_file = ".env"


settings = Settings()
