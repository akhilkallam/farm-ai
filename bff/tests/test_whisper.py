import pytest
from unittest.mock import MagicMock, patch
from services.whisper import WhisperService


@pytest.fixture
def svc():
    return WhisperService(api_key="sk-test")


@pytest.mark.asyncio
async def test_transcribe_returns_text_and_language(svc, tmp_path):
    audio_file = tmp_path / "test.m4a"
    audio_file.write_bytes(b"fake-audio")

    mock_transcription = MagicMock()
    mock_transcription.text = "मेरी फसल में पीला रोग लग गया है"
    mock_transcription.language = "hi"

    mock_client = MagicMock()
    mock_client.audio.transcriptions.create = MagicMock(return_value=mock_transcription)

    with patch.object(svc, "_client", mock_client):
        result = await svc.transcribe(str(audio_file))

    assert result["text"] == "मेरी फसल में पीला रोग लग गया है"
    assert result["language"] == "hi"


@pytest.mark.asyncio
async def test_transcribe_calls_whisper_with_correct_model(svc, tmp_path):
    audio_file = tmp_path / "test.m4a"
    audio_file.write_bytes(b"fake-audio")

    mock_transcription = MagicMock()
    mock_transcription.text = "test"
    mock_transcription.language = "en"

    mock_client = MagicMock()
    mock_client.audio.transcriptions.create = MagicMock(return_value=mock_transcription)

    with patch.object(svc, "_client", mock_client):
        await svc.transcribe(str(audio_file))

    call_kwargs = mock_client.audio.transcriptions.create.call_args
    assert call_kwargs.kwargs["model"] == "whisper-1"
