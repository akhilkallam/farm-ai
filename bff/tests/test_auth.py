import pytest
from unittest.mock import MagicMock, patch


@pytest.mark.asyncio
async def test_send_otp_returns_200(client):
    mock_otp_svc = MagicMock()
    mock_otp_svc.send = MagicMock()

    with patch("routers.auth.get_otp_service", return_value=mock_otp_svc):
        response = await client.post(
            "/auth/otp/send",
            json={"phone": "+919876543210"},
        )

    assert response.status_code == 200
    assert response.json() == {"message": "OTP sent"}


@pytest.mark.asyncio
async def test_verify_otp_returns_token_on_success(client):
    mock_otp_svc = MagicMock()
    mock_otp_svc.verify = MagicMock(return_value=True)

    mock_jwt_svc = MagicMock()
    mock_jwt_svc.create_token = MagicMock(return_value="test.jwt.token")

    with patch("routers.auth.get_otp_service", return_value=mock_otp_svc), \
         patch("routers.auth.get_jwt_service", return_value=mock_jwt_svc):
        response = await client.post(
            "/auth/otp/verify",
            json={"phone": "+919876543210", "otp": "123456"},
        )

    assert response.status_code == 200
    assert response.json()["token"] == "test.jwt.token"
    assert response.json()["farmer_id"] == "+919876543210"


@pytest.mark.asyncio
async def test_verify_otp_returns_401_on_wrong_otp(client):
    mock_otp_svc = MagicMock()
    mock_otp_svc.verify = MagicMock(return_value=False)

    with patch("routers.auth.get_otp_service", return_value=mock_otp_svc):
        response = await client.post(
            "/auth/otp/verify",
            json={"phone": "+919876543210", "otp": "000000"},
        )

    assert response.status_code == 401
