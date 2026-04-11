from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from services.otp_service import get_otp_service
from services.jwt_service import get_jwt_service

router = APIRouter(prefix="/auth", tags=["auth"])


class SendOTPRequest(BaseModel):
    phone: str


class VerifyOTPRequest(BaseModel):
    phone: str
    otp: str


@router.post("/otp/send")
def send_otp(body: SendOTPRequest):
    otp_service = get_otp_service()
    otp_service.send(phone=body.phone)
    return {"message": "OTP sent"}


@router.post("/otp/verify")
def verify_otp(body: VerifyOTPRequest):
    otp_service = get_otp_service()
    if not otp_service.verify(phone=body.phone, otp=body.otp):
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")

    jwt_service = get_jwt_service()
    token = jwt_service.create_token(farmer_id=body.phone)
    return {"token": token, "farmer_id": body.phone}
