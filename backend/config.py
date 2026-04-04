"""
config.py — Central settings for FarmAI backend.

📖 LEARNING NOTE:
    We use pydantic-settings here. It reads from .env automatically.
    Any service can do `from config import settings` and get typed config.
    This is a best practice — no hardcoded strings anywhere in the codebase.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── Anthropic ──────────────────────────────────────────────
    anthropic_api_key: str = "sk-ant-placeholder"
    claude_model: str = "claude-sonnet-4-20250514"

    # ── Database ───────────────────────────────────────────────
    postgres_url: str = "postgresql://farmai:farmai123@localhost:5432/farmai"
    postgres_url_async: str = "postgresql+asyncpg://farmai:farmai123@localhost:5432/farmai"

    # ── Redis ──────────────────────────────────────────────────
    redis_url: str = "redis://localhost:6379"

    # ── External APIs ──────────────────────────────────────────
    openweather_api_key: str = ""
    agmarknet_api_key: str = ""

    # ── MCP Server ─────────────────────────────────────────────
    mcp_server_url: str = "http://localhost:8001/sse"
    mcp_server_port: int = 8001

    # ── FastAPI ────────────────────────────────────────────────
    api_port: int = 8000
    api_host: str = "0.0.0.0"
    cors_origins: list[str] = ["http://localhost:3000"]

    # ── App ────────────────────────────────────────────────────
    environment: str = "development"
    log_level: str = "INFO"

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """
    Cached settings instance.
    lru_cache means we only read .env ONCE, not on every request.
    """
    return Settings()


# Convenience alias — import this everywhere
settings = get_settings()
