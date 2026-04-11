from __future__ import annotations

import pytest
from unittest.mock import AsyncMock, MagicMock, patch


def _make_mocks():
    whisper = MagicMock()
    whisper.transcribe = AsyncMock(return_value={"text": "मेरी फसल में पीला रोग", "language": "hi"})

    translation = MagicMock()
    translation.translate = MagicMock(side_effect=lambda text, target_language, **kw: {
        ("मेरी फसल में पीला रोग", "en"): "Yellow disease in my crop",
        ("Use neem oil spray", "hi"): "नीम तेल स्प्रे का उपयोग करें",
    }.get((text, target_language), text))

    backend = MagicMock()
    backend.chat = AsyncMock(return_value={
        "response": "Use neem oil spray",
        "agent_used": "pest_detector",
        "tools_used": [],
        "rag_used": True,
    })

    tts = MagicMock()
    tts.synthesize = AsyncMock(return_value=b"mp3-bytes")

    audio_store = MagicMock()
    audio_store.save = MagicMock(return_value="http://localhost:8002/audio/uuid.mp3")

    return whisper, translation, backend, tts, audio_store


@pytest.mark.asyncio
async def test_voice_chat_returns_expected_fields(client, tmp_path):
    audio_file = tmp_path / "test.m4a"
    audio_file.write_bytes(b"fake-audio")

    whisper, translation, backend, tts, audio_store = _make_mocks()

    with patch("routers.voice.get_whisper_service", return_value=whisper), \
         patch("routers.voice.get_translation_service", return_value=translation), \
         patch("routers.voice.get_backend_client", return_value=backend), \
         patch("routers.voice.get_tts_service", return_value=tts), \
         patch("routers.voice.get_audio_store", return_value=audio_store):
        response = await client.post(
            "/voice/chat",
            data={"farmer_id": "farmer-1"},
            files={"audio": ("test.m4a", audio_file.read_bytes(), "audio/m4a")},
        )

    assert response.status_code == 200
    body = response.json()
    assert body["language_detected"] == "hi"
    assert body["text_response"] == "Use neem oil spray"
    assert body["translated_response"] == "नीम तेल स्प्रे का उपयोग करें"
    assert body["audio_url"] == "http://localhost:8002/audio/uuid.mp3"
    assert body["agent_used"] == "pest_detector"
    assert body["queued"] is False


@pytest.mark.asyncio
async def test_text_chat_returns_expected_fields(client):
    translation = MagicMock()
    translation.translate = MagicMock(side_effect=lambda text, target_language, **kw: {
        ("मेरी फसल में पीला रोग", "en"): "Yellow disease in my crop",
        ("Use neem oil spray", "hi"): "नीम तेल स्प्रे का उपयोग करें",
    }.get((text, target_language), text))

    backend = MagicMock()
    backend.chat = AsyncMock(return_value={
        "response": "Use neem oil spray",
        "agent_used": "pest_detector",
        "tools_used": [],
        "rag_used": True,
    })

    tts = MagicMock()
    tts.synthesize = AsyncMock(return_value=b"mp3-bytes")

    audio_store = MagicMock()
    audio_store.save = MagicMock(return_value="http://localhost:8002/audio/uuid.mp3")

    with patch("routers.voice.get_translation_service", return_value=translation), \
         patch("routers.voice.get_backend_client", return_value=backend), \
         patch("routers.voice.get_tts_service", return_value=tts), \
         patch("routers.voice.get_audio_store", return_value=audio_store):
        response = await client.post(
            "/text/chat",
            json={
                "farmer_id": "farmer-1",
                "text": "मेरी फसल में पीला रोग",
                "language": "hi",
            },
        )

    assert response.status_code == 200
    body = response.json()
    assert body["text_response"] == "Use neem oil spray"
    assert body["translated_response"] == "नीम तेल स्प्रे का उपयोग करें"
    assert body["audio_url"] == "http://localhost:8002/audio/uuid.mp3"
