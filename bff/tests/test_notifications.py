from __future__ import annotations

import pytest
from unittest.mock import MagicMock, patch


@pytest.mark.asyncio
async def test_register_device_token_returns_200(client):
    mock_redis = MagicMock()

    with patch("routers.notifications.get_redis_client", return_value=mock_redis):
        response = await client.post(
            "/notifications/register",
            json={
                "farmer_id": "farmer-1",
                "device_token": "fcm-token-abc123",
                "platform": "fcm",
            },
        )

    assert response.status_code == 200
    assert response.json() == {"message": "Device registered"}


@pytest.mark.asyncio
async def test_register_stores_token_in_redis(client):
    mock_redis = MagicMock()

    with patch("routers.notifications.get_redis_client", return_value=mock_redis):
        await client.post(
            "/notifications/register",
            json={
                "farmer_id": "farmer-1",
                "device_token": "fcm-token-abc123",
                "platform": "fcm",
            },
        )

    mock_redis.hset.assert_called_once_with(
        "device_tokens:farmer-1",
        "fcm",
        "fcm-token-abc123",
    )
    mock_redis.expire.assert_called_once_with("device_tokens:farmer-1", 30 * 24 * 3600)


@pytest.mark.asyncio
async def test_register_rejects_invalid_platform(client):
    mock_redis = MagicMock()

    with patch("routers.notifications.get_redis_client", return_value=mock_redis):
        response = await client.post(
            "/notifications/register",
            json={
                "farmer_id": "farmer-1",
                "device_token": "token",
                "platform": "unknown-platform",
            },
        )

    assert response.status_code == 422
