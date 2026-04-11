from __future__ import annotations

from google.cloud import translate_v2 as translate


class TranslationService:
    def __init__(self, api_key: str):
        self._client = translate.Client(client_options={"api_key": api_key})

    def detect_language(self, text: str) -> str:
        """Returns BCP-47 language code, e.g. 'hi', 'te', 'pa', 'mr'."""
        result = self._client.detect_language(text)
        return result["language"]

    def translate(
        self,
        text: str,
        target_language: str,
        source_language: str | None = None,
    ) -> str:
        """Translate text. Returns original if source == target."""
        if source_language == target_language:
            return text
        result = self._client.translate(
            text,
            target_language=target_language,
            source_language=source_language,
        )
        return result["translatedText"]


def get_translation_service() -> TranslationService:
    from config import settings
    return TranslationService(api_key=settings.google_translate_api_key)
