from datetime import datetime, timedelta

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

security = HTTPBearer()


class JWTService:
    def __init__(self, secret: str, expiry_days: int):
        self.secret = secret
        self.expiry_days = expiry_days
        self.algorithm = "HS256"

    def create_token(self, farmer_id: str) -> str:
        payload = {
            "sub": farmer_id,
            "exp": datetime.utcnow() + timedelta(days=self.expiry_days),
        }
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)

    def decode_token(self, token: str) -> str:
        try:
            payload = jwt.decode(token, self.secret, algorithms=[self.algorithm])
            return payload["sub"]
        except JWTError:
            raise HTTPException(status_code=401, detail="Invalid or expired token")


def get_jwt_service() -> JWTService:
    from config import settings
    return JWTService(secret=settings.jwt_secret, expiry_days=settings.jwt_expiry_days)


def get_current_farmer_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    jwt_service: JWTService = Depends(get_jwt_service),
) -> str:
    """FastAPI dependency — extracts and validates farmer_id from Bearer token."""
    return jwt_service.decode_token(credentials.credentials)
