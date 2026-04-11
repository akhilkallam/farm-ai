from __future__ import annotations

import os
import tempfile

from fastapi import APIRouter, File, Form, UploadFile
from pydantic import BaseModel

from services.audio_store import get_audio_store
from services.backend_client import get_backend_client
from services.translation import get_translation_service
from services.tts import get_tts_service
from services.whisper import get_whisper_service

router = APIRouter(tags=["voice"])


async def _process_text_to_response(
    farmer_id: str,
    text_en: str,
    language: str,
    queued: bool = False,
) -> dict:
    """Shared pipeline: English text -> agent -> translate -> TTS -> response dict."""
    backend = get_backend_client()
    agent_result = await backend.chat(farmer_id=farmer_id, message=text_en)
    response_en = agent_result["response"]

    translation = get_translation_service()
    translated = (
        translation.translate(response_en, target_language=language, source_language="en")
        if language != "en"
        else response_en
    )

    tts = get_tts_service()
    audio_bytes = await tts.synthesize(translated)

    audio_store = get_audio_store()
    audio_url = audio_store.save(audio_bytes)

    return {
        "text_response": response_en,
        "translated_response": translated,
        "audio_url": audio_url,
        "agent_used": agent_result.get("agent_used", "unknown"),
        "language_detected": language,
        "queued": queued,
    }


@router.post("/voice/chat")
async def voice_chat(
    farmer_id: str = Form(...),
    audio: UploadFile = File(...),
    language_hint: str = Form(default=""),
):
    """Full voice pipeline: audio in -> Whisper -> translate -> agent -> TTS -> audio out."""
    suffix = os.path.splitext(audio.filename or "audio.m4a")[1] or ".m4a"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await audio.read())
        tmp_path = tmp.name

    try:
        whisper = get_whisper_service()
        stt_result = await whisper.transcribe(tmp_path)
        text = stt_result["text"]
        language = stt_result["language"] or language_hint or "hi"

        translation = get_translation_service()
        text_en = (
            translation.translate(text, target_language="en", source_language=language)
            if language != "en"
            else text
        )

        return await _process_text_to_response(
            farmer_id=farmer_id,
            text_en=text_en,
            language=language,
        )
    finally:
        os.unlink(tmp_path)


class TextChatRequest(BaseModel):
    farmer_id: str
    text: str
    language: str = "hi"
    queued: bool = False


@router.post("/text/chat")
async def text_chat(body: TextChatRequest):
    """Text input pipeline: translate -> agent -> TTS -> audio out."""
    translation = get_translation_service()
    text_en = (
        translation.translate(body.text, target_language="en", source_language=body.language)
        if body.language != "en"
        else body.text
    )

    return await _process_text_to_response(
        farmer_id=body.farmer_id,
        text_en=text_en,
        language=body.language,
        queued=body.queued,
    )
