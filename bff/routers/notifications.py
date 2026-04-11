from __future__ import annotations

from typing import Literal

import redis as redis_lib
from fastapi import APIRouter
from pydantic import BaseModel

from config import settings

router = APIRouter(prefix="/notifications", tags=["notifications"])

TOKEN_TTL_SECONDS = 30 * 24 * 3600  # 30 days


def get_redis_client():
    return redis_lib.from_url(settings.redis_url, decode_responses=True)


class RegisterDeviceRequest(BaseModel):
    farmer_id: str
    device_token: str
    platform: Literal["fcm", "apns"]


@router.post("/register")
def register_device(body: RegisterDeviceRequest):
    """Store device push token in Redis. Key: device_tokens:{farmer_id}."""
    redis = get_redis_client()
    key = f"device_tokens:{body.farmer_id}"
    # Use pipeline to make hset + expire atomic
    with redis.pipeline() as pipe:
        pipe.hset(key, body.platform, body.device_token)
        pipe.expire(key, TOKEN_TTL_SECONDS)
        pipe.execute()
    return {"message": "Device registered"}
