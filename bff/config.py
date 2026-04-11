from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    app_name: str = "Farm-AI BFF"
    debug: bool = False
    bff_port: int = 8002

    # Auth
    jwt_secret: str = "change-me-in-production"
    jwt_expiry_days: int = 7
    otp_expiry_seconds: int = 300
    otp_length: int = 6

    # SMS (Twilio)
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_phone_number: str = ""

    # Redis
    redis_url: str = "redis://localhost:6379"

    # Existing backend
    backend_url: str = "http://localhost:8000"

    # OpenAI (Whisper + TTS)
    openai_api_key: str = ""

    # Google Cloud Translation
    google_translate_api_key: str = ""

    # Audio storage
    audio_dir: str = "/tmp/audio"
    audio_ttl_hours: int = 1

    # CORS
    cors_origins: str = "http://localhost:3000"

    class Config:
        env_file = ".env"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
