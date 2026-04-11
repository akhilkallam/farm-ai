import openai


class WhisperService:
    def __init__(self, api_key: str):
        self._client = openai.OpenAI(api_key=api_key)

    async def transcribe(self, audio_path: str) -> dict[str, str]:
        """
        Transcribe audio file. Returns {"text": ..., "language": ...}.
        Language is BCP-47 code detected by Whisper (e.g. "hi", "te").
        """
        with open(audio_path, "rb") as f:
            transcription = self._client.audio.transcriptions.create(
                model="whisper-1",
                file=f,
                response_format="verbose_json",
            )
        return {"text": transcription.text, "language": transcription.language}


def get_whisper_service() -> WhisperService:
    from config import settings
    return WhisperService(api_key=settings.openai_api_key)
