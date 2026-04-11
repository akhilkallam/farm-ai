import random
import string


class OTPService:
    def __init__(
        self,
        redis_client,
        twilio_client,
        twilio_from: str,
        otp_expiry_seconds: int,
        otp_length: int,
    ):
        self._redis = redis_client
        self._twilio = twilio_client
        self._from = twilio_from
        self._expiry = otp_expiry_seconds
        self._length = otp_length

    def _generate(self) -> str:
        return "".join(random.choices(string.digits, k=self._length))

    def _redis_key(self, phone: str) -> str:
        return f"otp:{phone}"

    def send(self, phone: str) -> None:
        otp = self._generate()
        self._redis.setex(self._redis_key(phone), self._expiry, otp)
        self._twilio.messages.create(
            to=phone,
            from_=self._from,
            body=f"Your Farm-AI OTP is {otp}. Valid for {self._expiry // 60} minutes.",
        )

    def verify(self, phone: str, otp: str) -> bool:
        stored = self._redis.get(self._redis_key(phone))
        if stored is None:
            return False
        if stored != otp:
            return False
        self._redis.delete(self._redis_key(phone))
        return True


def get_otp_service() -> OTPService:
    import redis as redis_lib
    from twilio.rest import Client as TwilioClient
    from config import settings

    redis_client = redis_lib.from_url(settings.redis_url, decode_responses=True)
    twilio_client = TwilioClient(settings.twilio_account_sid, settings.twilio_auth_token)
    return OTPService(
        redis_client=redis_client,
        twilio_client=twilio_client,
        twilio_from=settings.twilio_phone_number,
        otp_expiry_seconds=settings.otp_expiry_seconds,
        otp_length=settings.otp_length,
    )
