import pytest
from unittest.mock import MagicMock, patch
from services.translation import TranslationService


@pytest.fixture
def svc():
    with patch("google.cloud.translate_v2.Client"):
        return TranslationService(api_key="test-key")


def test_detect_language_returns_code(svc):
    mock_client = MagicMock()
    mock_client.detect_language.return_value = {"language": "te", "confidence": 0.99}
    with patch.object(svc, "_client", mock_client):
        lang = svc.detect_language("నా పంట పెరుగుతోంది")
    assert lang == "te"


def test_translate_to_english(svc):
    mock_client = MagicMock()
    mock_client.translate.return_value = {"translatedText": "My crop is growing", "detectedSourceLanguage": "te"}
    with patch.object(svc, "_client", mock_client):
        result = svc.translate("నా పంట పెరుగుతోంది", target_language="en")
    assert result == "My crop is growing"


def test_translate_from_english_to_hindi(svc):
    mock_client = MagicMock()
    mock_client.translate.return_value = {"translatedText": "ड्रिप सिंचाई का उपयोग करें", "detectedSourceLanguage": "en"}
    with patch.object(svc, "_client", mock_client):
        result = svc.translate("Use drip irrigation", target_language="hi")
    assert result == "ड्रिप सिंचाई का उपयोग करें"


def test_skip_translation_when_already_english(svc):
    result = svc.translate("Hello", target_language="en", source_language="en")
    assert result == "Hello"
