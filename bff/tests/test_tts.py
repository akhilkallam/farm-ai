import pytest
from unittest.mock import MagicMock, patch
from services.tts import TTSService


@pytest.fixture
def svc():
    return TTSService(api_key="sk-test")


@pytest.mark.asyncio
async def test_synthesize_returns_bytes(svc):
    mock_response = MagicMock()
    mock_response.content = b"mp3-audio-bytes"

    mock_client = MagicMock()
    mock_client.audio.speech.create = MagicMock(return_value=mock_response)

    with patch.object(svc, "_client", mock_client):
        result = await svc.synthesize("ड्रिप सिंचाई का उपयोग करें")

    assert result == b"mp3-audio-bytes"


@pytest.mark.asyncio
async def test_synthesize_uses_mp3_format(svc):
    mock_response = MagicMock()
    mock_response.content = b"audio"

    mock_client = MagicMock()
    mock_client.audio.speech.create = MagicMock(return_value=mock_response)

    with patch.object(svc, "_client", mock_client):
        await svc.synthesize("Hello farmer")

    call_kwargs = mock_client.audio.speech.create.call_args
    assert call_kwargs.kwargs["response_format"] == "mp3"
