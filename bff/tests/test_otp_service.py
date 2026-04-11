import pytest
from unittest.mock import MagicMock
from services.otp_service import OTPService


@pytest.fixture
def svc():
    mock_redis = MagicMock()
    mock_twilio = MagicMock()
    return OTPService(
        redis_client=mock_redis,
        twilio_client=mock_twilio,
        twilio_from="+15005550006",
        otp_expiry_seconds=300,
        otp_length=6,
    )


def test_send_stores_otp_in_redis(svc):
    svc.send(phone="+919876543210")
    svc._redis.setex.assert_called_once()
    key, ttl, value = svc._redis.setex.call_args.args
    assert key == "otp:+919876543210"
    assert ttl == 300
    assert len(value) == 6
    assert value.isdigit()


def test_send_sends_sms_via_twilio(svc):
    svc.send(phone="+919876543210")
    svc._twilio.messages.create.assert_called_once()
    call_kwargs = svc._twilio.messages.create.call_args.kwargs
    assert call_kwargs["to"] == "+919876543210"
    assert call_kwargs["from_"] == "+15005550006"
    assert "OTP" in call_kwargs["body"]


def test_verify_returns_true_for_correct_otp(svc):
    svc._redis.get.return_value = "123456"
    result = svc.verify(phone="+919876543210", otp="123456")
    assert result is True
    svc._redis.delete.assert_called_once_with("otp:+919876543210")


def test_verify_returns_false_for_wrong_otp(svc):
    svc._redis.get.return_value = "123456"
    result = svc.verify(phone="+919876543210", otp="999999")
    assert result is False


def test_verify_returns_false_when_otp_expired(svc):
    svc._redis.get.return_value = None
    result = svc.verify(phone="+919876543210", otp="123456")
    assert result is False
