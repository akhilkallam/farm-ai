from __future__ import annotations

import pytest
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.asyncio
async def test_sync_pull_returns_farmer_and_history(client):
    mock_backend = MagicMock()
    mock_backend.get_farmer = AsyncMock(return_value={
        "id": "farmer-1",
        "name": "Raju Reddy",
        "state": "Telangana",
        "current_crops": ["rice"],
    })
    mock_backend.get_history = AsyncMock(return_value=[
        {"query": "q1", "response": "r1", "agent_used": "crop_advisor"}
    ])

    with patch("routers.sync.get_backend_client", return_value=mock_backend):
        response = await client.get("/sync/pull/farmer-1")

    assert response.status_code == 200
    body = response.json()
    assert body["farmer_profile"]["name"] == "Raju Reddy"
    assert len(body["recent_conversations"]) == 1


@pytest.mark.asyncio
async def test_sync_push_processes_text_requests_in_order(client):
    mock_text_chat = AsyncMock(return_value={
        "text_response": "Use drip irrigation",
        "translated_response": "ड्रिप सिंचाई",
        "audio_url": "http://localhost:8002/audio/uuid.mp3",
        "agent_used": "irrigation_planner",
        "language_detected": "hi",
        "queued": True,
    })

    with patch("routers.sync.text_chat", mock_text_chat):
        response = await client.post(
            "/sync/push",
            json={
                "requests": [
                    {
                        "id": "req-1",
                        "text": "मेरे खेत में पानी कितना देना है",
                        "farmer_id": "farmer-1",
                        "language": "hi",
                        "queued_at": "2026-04-09T10:00:00Z",
                    }
                ]
            },
        )

    assert response.status_code == 200
    body = response.json()
    assert len(body["results"]) == 1
    assert body["results"][0]["id"] == "req-1"
    assert body["results"][0]["success"] is True


@pytest.mark.asyncio
async def test_sync_push_marks_failed_request_on_error(client):
    mock_text_chat = AsyncMock(side_effect=Exception("Backend unavailable"))

    with patch("routers.sync.text_chat", mock_text_chat):
        response = await client.post(
            "/sync/push",
            json={
                "requests": [
                    {
                        "id": "req-fail",
                        "text": "test",
                        "farmer_id": "farmer-1",
                        "language": "hi",
                        "queued_at": "2026-04-09T10:00:00Z",
                    }
                ]
            },
        )

    assert response.status_code == 200
    body = response.json()
    assert body["results"][0]["success"] is False
    assert "error" in body["results"][0]
