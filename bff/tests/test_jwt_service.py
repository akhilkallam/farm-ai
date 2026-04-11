import pytest
from fastapi import HTTPException
from services.jwt_service import JWTService

SECRET = "test-secret-key-32-chars-minimum!!"


@pytest.fixture
def svc():
    return JWTService(secret=SECRET, expiry_days=7)


def test_create_and_decode_roundtrip(svc):
    token = svc.create_token(farmer_id="farmer-123")
    farmer_id = svc.decode_token(token)
    assert farmer_id == "farmer-123"


def test_decode_invalid_token_raises_401(svc):
    with pytest.raises(HTTPException) as exc_info:
        svc.decode_token("invalid.token.here")
    assert exc_info.value.status_code == 401


def test_decode_tampered_token_raises_401(svc):
    token = svc.create_token(farmer_id="farmer-123")
    tampered = token[:-5] + "XXXXX"
    with pytest.raises(HTTPException) as exc_info:
        svc.decode_token(tampered)
    assert exc_info.value.status_code == 401


def test_expired_token_raises_401(svc):
    expired_svc = JWTService(secret=SECRET, expiry_days=-1)
    token = expired_svc.create_token(farmer_id="farmer-123")
    with pytest.raises(HTTPException) as exc_info:
        svc.decode_token(token)
    assert exc_info.value.status_code == 401
