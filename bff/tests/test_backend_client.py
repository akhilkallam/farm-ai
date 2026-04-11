import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from services.backend_client import BackendClient


@pytest.fixture
def client():
    return BackendClient(backend_url="http://fake-backend:8000")


@pytest.mark.asyncio
async def test_chat_sends_correct_payload(client):
    mock_response = MagicMock()
    mock_response.json.return_value = {
        "response": "Use drip irrigation",
        "agent_used": "irrigation_planner",
        "tools_used": [],
        "rag_used": False,
    }
    mock_response.raise_for_status = MagicMock()

    with patch("httpx.AsyncClient.post", new_callable=AsyncMock, return_value=mock_response):
        result = await client.chat(farmer_id="farmer-1", message="How often to water wheat?")

    assert result["response"] == "Use drip irrigation"
    assert result["agent_used"] == "irrigation_planner"


@pytest.mark.asyncio
async def test_get_farmer_returns_profile(client):
    mock_response = MagicMock()
    mock_response.json.return_value = {
        "id": "farmer-1",
        "name": "Raju Reddy",
        "state": "Telangana",
        "current_crops": ["rice", "cotton"],
    }
    mock_response.raise_for_status = MagicMock()

    with patch("httpx.AsyncClient.get", new_callable=AsyncMock, return_value=mock_response):
        result = await client.get_farmer(farmer_id="farmer-1")

    assert result["name"] == "Raju Reddy"
    assert "rice" in result["current_crops"]


@pytest.mark.asyncio
async def test_get_history_returns_list(client):
    mock_response = MagicMock()
    mock_response.json.return_value = [
        {"query": "q1", "response": "r1", "agent_used": "crop_advisor"}
    ]
    mock_response.raise_for_status = MagicMock()

    with patch("httpx.AsyncClient.get", new_callable=AsyncMock, return_value=mock_response):
        result = await client.get_history(farmer_id="farmer-1")

    assert len(result) == 1
    assert result[0]["query"] == "q1"
