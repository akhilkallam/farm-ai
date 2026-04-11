import openai


class TTSService:
    def __init__(self, api_key: str):
        self._client = openai.OpenAI(api_key=api_key)

    async def synthesize(self, text: str, voice: str = "alloy") -> bytes:
        """Convert text to MP3 audio bytes."""
        response = self._client.audio.speech.create(
            model="tts-1",
            voice=voice,
            input=text,
            response_format="mp3",
        )
        return response.content


def get_tts_service() -> TTSService:
    from config import settings
    return TTSService(api_key=settings.openai_api_key)
