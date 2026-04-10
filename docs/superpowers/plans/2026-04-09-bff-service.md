# Farm-AI BFF Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Backend for Frontend (BFF) FastAPI service that handles voice pipeline (STT → translate → agent → TTS), phone OTP/JWT auth, offline sync, and push notification token registration.

**Architecture:** New FastAPI service in `bff/` on port 8002. Sits between Flutter/Next.js clients and the existing backend (port 8000). The existing backend is never touched. The BFF owns: Whisper STT, Google Cloud Translation, OpenAI TTS, OTP via Twilio + Redis, JWT auth, sync, and device token storage in Redis.

**Tech Stack:** FastAPI 0.115, OpenAI Python SDK (Whisper + TTS), Google Cloud Translation API, python-jose (JWT), Twilio (SMS), Redis (OTP TTL + device tokens), httpx (async backend calls), pytest + pytest-asyncio + httpx AsyncClient

---

## File Map

| File | Responsibility |
|---|---|
| `bff/main.py` | FastAPI app, CORS, route registration, lifespan (audio cleanup task) |
| `bff/config.py` | Pydantic settings — reads all env vars |
| `bff/requirements.txt` | Python dependencies |
| `bff/Dockerfile` | Container image |
| `bff/routers/__init__.py` | Empty |
| `bff/routers/auth.py` | `POST /auth/otp/send`, `POST /auth/otp/verify` |
| `bff/routers/voice.py` | `POST /voice/chat`, `POST /text/chat` |
| `bff/routers/sync.py` | `POST /sync/push`, `GET /sync/pull/{farmer_id}` |
| `bff/routers/notifications.py` | `POST /notifications/register` |
| `bff/services/__init__.py` | Empty |
| `bff/services/audio_store.py` | Save TTS audio to `/tmp/audio/`, serve URL, background cleanup |
| `bff/services/backend_client.py` | Async HTTP calls to existing `/api/chat` and `/api/farmer/{id}` |
| `bff/services/translation.py` | Google Cloud Translation: detect language + translate text |
| `bff/services/whisper.py` | OpenAI Whisper: audio file → transcribed text + detected language |
| `bff/services/tts.py` | OpenAI TTS: text → audio bytes |
| `bff/services/jwt_service.py` | Create JWT, decode JWT, FastAPI `Depends` auth dependency |
| `bff/services/otp_service.py` | Generate OTP, store in Redis with TTL, verify, send via Twilio |
| `bff/tests/__init__.py` | Empty |
| `bff/tests/conftest.py` | pytest fixtures: test client, env var setup |
| `bff/tests/test_health.py` | Health endpoint |
| `bff/tests/test_audio_store.py` | Audio save/serve/cleanup |
| `bff/tests/test_backend_client.py` | Backend HTTP calls with mocked httpx |
| `bff/tests/test_translation.py` | Language detection + translation with mocked Google API |
| `bff/tests/test_whisper.py` | STT with mocked OpenAI |
| `bff/tests/test_tts.py` | TTS with mocked OpenAI |
| `bff/tests/test_jwt_service.py` | JWT create/decode/dependency |
| `bff/tests/test_otp_service.py` | OTP generate/store/verify with mocked Redis + Twilio |
| `bff/tests/test_auth.py` | Auth router endpoints |
| `bff/tests/test_voice.py` | Voice pipeline endpoints |
| `bff/tests/test_sync.py` | Sync endpoints |
| `bff/tests/test_notifications.py` | Notification registration endpoint |
| `docker-compose.yml` | Add `bff` service on port 8002 |
| `.env.example` | Add BFF-specific env vars |

---

## Task 1: Project scaffold, config, and health endpoint

**Files:**
- Create: `bff/requirements.txt`
- Create: `bff/config.py`
- Create: `bff/main.py`
- Create: `bff/routers/__init__.py`
- Create: `bff/services/__init__.py`
- Create: `bff/tests/__init__.py`
- Create: `bff/tests/conftest.py`
- Create: `bff/tests/test_health.py`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p bff/routers bff/services bff/tests
touch bff/routers/__init__.py bff/services/__init__.py bff/tests/__init__.py
```

- [ ] **Step 2: Write `bff/requirements.txt`**

```
fastapi==0.115.0
uvicorn[standard]==0.30.0
pydantic-settings==2.3.0
httpx==0.27.0
openai==1.30.0
google-cloud-translate==3.15.0
python-jose[cryptography]==3.3.0
twilio==9.0.0
redis==5.0.4
python-multipart==0.0.9
aiofiles==23.2.1
pytest==8.2.0
pytest-asyncio==0.23.7
```

- [ ] **Step 3: Write `bff/config.py`**

```python
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    app_name: str = "Farm-AI BFF"
    debug: bool = False
    bff_port: int = 8002

    # Auth
    jwt_secret: str = "change-me-in-production"
    jwt_expiry_days: int = 7
    otp_expiry_seconds: int = 300  # 5 minutes
    otp_length: int = 6

    # SMS (Twilio)
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_phone_number: str = ""

    # Redis (OTP storage + device tokens)
    redis_url: str = "redis://localhost:6379"

    # Existing backend
    backend_url: str = "http://localhost:8000"

    # OpenAI (Whisper + TTS)
    openai_api_key: str = ""

    # Google Cloud Translation
    google_translate_api_key: str = ""

    # Audio storage
    audio_dir: str = "/tmp/audio"
    audio_ttl_hours: int = 1

    # CORS
    cors_origins: str = "http://localhost:3000"

    class Config:
        env_file = ".env"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
```

- [ ] **Step 4: Write the failing health test `bff/tests/conftest.py`**

```python
import os
import sys
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport

# Set test env vars before importing app modules
os.environ.setdefault("JWT_SECRET", "test-secret-key-32-chars-minimum!!")
os.environ.setdefault("TWILIO_ACCOUNT_SID", "ACtest")
os.environ.setdefault("TWILIO_AUTH_TOKEN", "test-token")
os.environ.setdefault("TWILIO_PHONE_NUMBER", "+15005550006")
os.environ.setdefault("OPENAI_API_KEY", "sk-test")
os.environ.setdefault("GOOGLE_TRANSLATE_API_KEY", "test-key")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")
os.environ.setdefault("BACKEND_URL", "http://localhost:8000")
os.environ.setdefault("AUDIO_DIR", "/tmp/test-audio")

# Add bff/ to path so imports resolve without package prefix
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest_asyncio.fixture
async def client():
    from main import app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
```

- [ ] **Step 5: Write `bff/tests/test_health.py`**

```python
import pytest


@pytest.mark.asyncio
async def test_health_returns_ok(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "farm-ai-bff"}
```

- [ ] **Step 6: Run test to verify it fails**

```bash
cd bff && pip install -r requirements.txt && pytest tests/test_health.py -v
```

Expected: `FAILED` — `ImportError: No module named 'main'` or `404`

- [ ] **Step 7: Write `bff/main.py`**

```python
import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def _audio_cleanup_loop():
    """Delete audio files older than audio_ttl_hours every hour."""
    while True:
        await asyncio.sleep(3600)
        try:
            cutoff = time.time() - (settings.audio_ttl_hours * 3600)
            for fname in os.listdir(settings.audio_dir):
                fpath = os.path.join(settings.audio_dir, fname)
                if os.path.isfile(fpath) and os.path.getmtime(fpath) < cutoff:
                    os.remove(fpath)
                    logger.debug(f"Deleted old audio file: {fname}")
        except Exception as e:
            logger.warning(f"Audio cleanup error: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    os.makedirs(settings.audio_dir, exist_ok=True)
    cleanup_task = asyncio.create_task(_audio_cleanup_loop())
    logger.info(f"Farm-AI BFF starting on port {settings.bff_port}")
    yield
    cleanup_task.cancel()


app = FastAPI(title=settings.app_name, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve generated audio files
app.mount("/audio", StaticFiles(directory=settings.audio_dir), name="audio")

# Routers registered in later tasks


@app.get("/health")
async def health():
    return {"status": "ok", "service": "farm-ai-bff"}
```

- [ ] **Step 8: Run test to verify it passes**

```bash
cd bff && pytest tests/test_health.py -v
```

Expected: `PASSED`

- [ ] **Step 9: Commit**

```bash
cd bff && git add . && git commit -m "feat(bff): scaffold project, config, health endpoint"
```

---

## Task 2: Audio store service

**Files:**
- Create: `bff/services/audio_store.py`
- Create: `bff/tests/test_audio_store.py`

- [ ] **Step 1: Write `bff/tests/test_audio_store.py`**

```python
import os
import pytest
from services.audio_store import AudioStore


@pytest.fixture
def store(tmp_path):
    return AudioStore(audio_dir=str(tmp_path), base_url="http://test")


def test_save_returns_url_and_creates_file(store, tmp_path):
    audio_bytes = b"fake-audio-data"
    url = store.save(audio_bytes)
    assert url.startswith("http://test/audio/")
    filename = url.split("/")[-1]
    assert os.path.exists(os.path.join(str(tmp_path), filename))


def test_save_creates_mp3_file(store, tmp_path):
    url = store.save(b"data")
    filename = url.split("/")[-1]
    assert filename.endswith(".mp3")


def test_cleanup_removes_old_files(store, tmp_path):
    import time
    url = store.save(b"data")
    filename = url.split("/")[-1]
    fpath = os.path.join(str(tmp_path), filename)
    # Backdate the file by 2 hours
    old_time = time.time() - 7200
    os.utime(fpath, (old_time, old_time))
    store.cleanup(ttl_hours=1)
    assert not os.path.exists(fpath)


def test_cleanup_keeps_recent_files(store, tmp_path):
    url = store.save(b"data")
    filename = url.split("/")[-1]
    fpath = os.path.join(str(tmp_path), filename)
    store.cleanup(ttl_hours=1)
    assert os.path.exists(fpath)
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_audio_store.py -v
```

Expected: `FAILED` — `ModuleNotFoundError: No module named 'services.audio_store'`

- [ ] **Step 3: Write `bff/services/audio_store.py`**

```python
import os
import time
import uuid


class AudioStore:
    def __init__(self, audio_dir: str, base_url: str):
        self.audio_dir = audio_dir
        self.base_url = base_url.rstrip("/")
        os.makedirs(audio_dir, exist_ok=True)

    def save(self, audio_bytes: bytes) -> str:
        """Save audio bytes to disk. Returns the public URL."""
        filename = f"{uuid.uuid4()}.mp3"
        fpath = os.path.join(self.audio_dir, filename)
        with open(fpath, "wb") as f:
            f.write(audio_bytes)
        return f"{self.base_url}/audio/{filename}"

    def cleanup(self, ttl_hours: int) -> None:
        """Delete audio files older than ttl_hours."""
        cutoff = time.time() - (ttl_hours * 3600)
        for fname in os.listdir(self.audio_dir):
            fpath = os.path.join(self.audio_dir, fname)
            if os.path.isfile(fpath) and os.path.getmtime(fpath) < cutoff:
                os.remove(fpath)


def get_audio_store() -> AudioStore:
    from config import settings
    return AudioStore(
        audio_dir=settings.audio_dir,
        base_url=f"http://localhost:{settings.bff_port}",
    )
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_audio_store.py -v
```

Expected: `4 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/audio_store.py bff/tests/test_audio_store.py
git commit -m "feat(bff): add audio store service"
```

---

## Task 3: Backend client service

**Files:**
- Create: `bff/services/backend_client.py`
- Create: `bff/tests/test_backend_client.py`

- [ ] **Step 1: Write `bff/tests/test_backend_client.py`**

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_backend_client.py -v
```

Expected: `FAILED` — `ModuleNotFoundError`

- [ ] **Step 3: Write `bff/services/backend_client.py`**

```python
import httpx
from typing import Any


class BackendClient:
    def __init__(self, backend_url: str):
        self.backend_url = backend_url.rstrip("/")

    async def chat(self, farmer_id: str, message: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                f"{self.backend_url}/api/chat",
                json={"farmer_id": farmer_id, "message": message},
            )
            resp.raise_for_status()
            return resp.json()

    async def get_farmer(self, farmer_id: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(f"{self.backend_url}/api/farmer/{farmer_id}")
            resp.raise_for_status()
            return resp.json()

    async def get_history(self, farmer_id: str) -> list[dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(f"{self.backend_url}/api/history/{farmer_id}")
            resp.raise_for_status()
            return resp.json()


def get_backend_client() -> BackendClient:
    from config import settings
    return BackendClient(backend_url=settings.backend_url)
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_backend_client.py -v
```

Expected: `3 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/backend_client.py bff/tests/test_backend_client.py
git commit -m "feat(bff): add backend client service"
```

---

## Task 4: Translation service

**Files:**
- Create: `bff/services/translation.py`
- Create: `bff/tests/test_translation.py`

- [ ] **Step 1: Write `bff/tests/test_translation.py`**

```python
import pytest
from unittest.mock import MagicMock, patch
from services.translation import TranslationService

SUPPORTED_LANGUAGES = ["hi", "te", "pa", "mr"]


@pytest.fixture
def svc():
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_translation.py -v
```

Expected: `FAILED` — `ModuleNotFoundError`

- [ ] **Step 3: Write `bff/services/translation.py`**

```python
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_translation.py -v
```

Expected: `4 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/translation.py bff/tests/test_translation.py
git commit -m "feat(bff): add Google Cloud translation service"
```

---

## Task 5: Whisper STT service

**Files:**
- Create: `bff/services/whisper.py`
- Create: `bff/tests/test_whisper.py`

- [ ] **Step 1: Write `bff/tests/test_whisper.py`**

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_whisper.py -v
```

Expected: `FAILED` — `ModuleNotFoundError`

- [ ] **Step 3: Write `bff/services/whisper.py`**

```python
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_whisper.py -v
```

Expected: `2 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/whisper.py bff/tests/test_whisper.py
git commit -m "feat(bff): add Whisper STT service"
```

---

## Task 6: TTS service

**Files:**
- Create: `bff/services/tts.py`
- Create: `bff/tests/test_tts.py`

- [ ] **Step 1: Write `bff/tests/test_tts.py`**

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_tts.py -v
```

Expected: `FAILED` — `ModuleNotFoundError`

- [ ] **Step 3: Write `bff/services/tts.py`**

```python
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_tts.py -v
```

Expected: `2 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/tts.py bff/tests/test_tts.py
git commit -m "feat(bff): add OpenAI TTS service"
```

---

## Task 7: JWT service

**Files:**
- Create: `bff/services/jwt_service.py`
- Create: `bff/tests/test_jwt_service.py`

- [ ] **Step 1: Write `bff/tests/test_jwt_service.py`**

```python
import pytest
import time
from unittest.mock import patch
from fastapi import HTTPException
from services.jwt_service import JWTService

SECRET = "test-secret-key-32-chars-minimum!!"


@pytest.fixture
def svc():
    return JWTService(secret=SECRET, expiry_days=7)


def test_create_and_decode_roundtrip(svc):
    token = svc.create_token(farmer_id="farmer-123")
    farmer_id = svc.decode_token(token)
    assert farmer_id == "farmer-123"


def test_decode_invalid_token_raises_401(svc):
    with pytest.raises(HTTPException) as exc_info:
        svc.decode_token("invalid.token.here")
    assert exc_info.value.status_code == 401


def test_decode_tampered_token_raises_401(svc):
    token = svc.create_token(farmer_id="farmer-123")
    tampered = token[:-5] + "XXXXX"
    with pytest.raises(HTTPException) as exc_info:
        svc.decode_token(tampered)
    assert exc_info.value.status_code == 401


def test_expired_token_raises_401(svc):
    # Create a token with -1 day expiry (already expired)
    expired_svc = JWTService(secret=SECRET, expiry_days=-1)
    token = expired_svc.create_token(farmer_id="farmer-123")
    with pytest.raises(HTTPException) as exc_info:
        svc.decode_token(token)
    assert exc_info.value.status_code == 401
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_jwt_service.py -v
```

Expected: `FAILED` — `ModuleNotFoundError`

- [ ] **Step 3: Write `bff/services/jwt_service.py`**

```python
from datetime import datetime, timedelta

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

security = HTTPBearer()


class JWTService:
    def __init__(self, secret: str, expiry_days: int):
        self.secret = secret
        self.expiry_days = expiry_days
        self.algorithm = "HS256"

    def create_token(self, farmer_id: str) -> str:
        payload = {
            "sub": farmer_id,
            "exp": datetime.utcnow() + timedelta(days=self.expiry_days),
        }
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)

    def decode_token(self, token: str) -> str:
        try:
            payload = jwt.decode(token, self.secret, algorithms=[self.algorithm])
            return payload["sub"]
        except JWTError:
            raise HTTPException(status_code=401, detail="Invalid or expired token")


def get_jwt_service() -> JWTService:
    from config import settings
    return JWTService(secret=settings.jwt_secret, expiry_days=settings.jwt_expiry_days)


def get_current_farmer_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    jwt_service: JWTService = Depends(get_jwt_service),
) -> str:
    """FastAPI dependency — extracts and validates farmer_id from Bearer token."""
    return jwt_service.decode_token(credentials.credentials)
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_jwt_service.py -v
```

Expected: `4 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/jwt_service.py bff/tests/test_jwt_service.py
git commit -m "feat(bff): add JWT service and auth dependency"
```

---

## Task 8: OTP service

**Files:**
- Create: `bff/services/otp_service.py`
- Create: `bff/tests/test_otp_service.py`

- [ ] **Step 1: Write `bff/tests/test_otp_service.py`**

```python
import pytest
from unittest.mock import MagicMock, patch
from services.otp_service import OTPService


@pytest.fixture
def svc():
    mock_redis = MagicMock()
    mock_twilio = MagicMock()
    return OTPService(
        redis_client=mock_redis,
        twilio_client=mock_twilio,
        twilio_from="+15005550006",
        otp_expiry_seconds=300,
        otp_length=6,
    )


def test_send_stores_otp_in_redis(svc):
    svc.send(phone="+919876543210")
    svc._redis.setex.assert_called_once()
    key, ttl, value = svc._redis.setex.call_args.args
    assert key == "otp:+919876543210"
    assert ttl == 300
    assert len(value) == 6
    assert value.isdigit()


def test_send_sends_sms_via_twilio(svc):
    svc.send(phone="+919876543210")
    svc._twilio.messages.create.assert_called_once()
    call_kwargs = svc._twilio.messages.create.call_args.kwargs
    assert call_kwargs["to"] == "+919876543210"
    assert call_kwargs["from_"] == "+15005550006"
    assert "OTP" in call_kwargs["body"]


def test_verify_returns_true_for_correct_otp(svc):
    svc._redis.get.return_value = "123456"
    result = svc.verify(phone="+919876543210", otp="123456")
    assert result is True
    svc._redis.delete.assert_called_once_with("otp:+919876543210")


def test_verify_returns_false_for_wrong_otp(svc):
    svc._redis.get.return_value = "123456"
    result = svc.verify(phone="+919876543210", otp="999999")
    assert result is False


def test_verify_returns_false_when_otp_expired(svc):
    svc._redis.get.return_value = None
    result = svc.verify(phone="+919876543210", otp="123456")
    assert result is False
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_otp_service.py -v
```

Expected: `FAILED` — `ModuleNotFoundError`

- [ ] **Step 3: Write `bff/services/otp_service.py`**

```python
import random
import string


class OTPService:
    def __init__(
        self,
        redis_client,
        twilio_client,
        twilio_from: str,
        otp_expiry_seconds: int,
        otp_length: int,
    ):
        self._redis = redis_client
        self._twilio = twilio_client
        self._from = twilio_from
        self._expiry = otp_expiry_seconds
        self._length = otp_length

    def _generate(self) -> str:
        return "".join(random.choices(string.digits, k=self._length))

    def _redis_key(self, phone: str) -> str:
        return f"otp:{phone}"

    def send(self, phone: str) -> None:
        otp = self._generate()
        self._redis.setex(self._redis_key(phone), self._expiry, otp)
        self._twilio.messages.create(
            to=phone,
            from_=self._from,
            body=f"Your Farm-AI OTP is {otp}. Valid for {self._expiry // 60} minutes.",
        )

    def verify(self, phone: str, otp: str) -> bool:
        stored = self._redis.get(self._redis_key(phone))
        if stored is None:
            return False
        if stored != otp:
            return False
        self._redis.delete(self._redis_key(phone))
        return True


def get_otp_service() -> OTPService:
    import redis as redis_lib
    from twilio.rest import Client as TwilioClient
    from config import settings

    redis_client = redis_lib.from_url(settings.redis_url, decode_responses=True)
    twilio_client = TwilioClient(settings.twilio_account_sid, settings.twilio_auth_token)
    return OTPService(
        redis_client=redis_client,
        twilio_client=twilio_client,
        twilio_from=settings.twilio_phone_number,
        otp_expiry_seconds=settings.otp_expiry_seconds,
        otp_length=settings.otp_length,
    )
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd bff && pytest tests/test_otp_service.py -v
```

Expected: `5 passed`

- [ ] **Step 5: Commit**

```bash
git add bff/services/otp_service.py bff/tests/test_otp_service.py
git commit -m "feat(bff): add OTP service with Redis TTL and Twilio SMS"
```

---

## Task 9: Auth router

**Files:**
- Create: `bff/routers/auth.py`
- Create: `bff/tests/test_auth.py`
- Modify: `bff/main.py` — register auth router

- [ ] **Step 1: Write `bff/tests/test_auth.py`**

```python
import pytest
from unittest.mock import MagicMock, patch


@pytest.mark.asyncio
async def test_send_otp_returns_200(client):
    mock_otp_svc = MagicMock()
    mock_otp_svc.send = MagicMock()

    with patch("routers.auth.get_otp_service", return_value=mock_otp_svc):
        response = await client.post(
            "/auth/otp/send",
            json={"phone": "+919876543210"},
        )

    assert response.status_code == 200
    assert response.json() == {"message": "OTP sent"}


@pytest.mark.asyncio
async def test_verify_otp_returns_token_on_success(client):
    mock_otp_svc = MagicMock()
    mock_otp_svc.verify = MagicMock(return_value=True)

    mock_jwt_svc = MagicMock()
    mock_jwt_svc.create_token = MagicMock(return_value="test.jwt.token")

    with patch("routers.auth.get_otp_service", return_value=mock_otp_svc), \
         patch("routers.auth.get_jwt_service", return_value=mock_jwt_svc):
        response = await client.post(
            "/auth/otp/verify",
            json={"phone": "+919876543210", "otp": "123456"},
        )

    assert response.status_code == 200
    assert response.json()["token"] == "test.jwt.token"
    assert response.json()["farmer_id"] == "+919876543210"


@pytest.mark.asyncio
async def test_verify_otp_returns_401_on_wrong_otp(client):
    mock_otp_svc = MagicMock()
    mock_otp_svc.verify = MagicMock(return_value=False)

    with patch("routers.auth.get_otp_service", return_value=mock_otp_svc):
        response = await client.post(
            "/auth/otp/verify",
            json={"phone": "+919876543210", "otp": "000000"},
        )

    assert response.status_code == 401
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_auth.py -v
```

Expected: `FAILED` — `404` (router not registered yet)

- [ ] **Step 3: Write `bff/routers/auth.py`**

```python
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from services.otp_service import get_otp_service
from services.jwt_service import get_jwt_service

router = APIRouter(prefix="/auth", tags=["auth"])


class SendOTPRequest(BaseModel):
    phone: str


class VerifyOTPRequest(BaseModel):
    phone: str
    otp: str


@router.post("/otp/send")
def send_otp(body: SendOTPRequest):
    otp_service = get_otp_service()
    otp_service.send(phone=body.phone)
    return {"message": "OTP sent"}


@router.post("/otp/verify")
def verify_otp(body: VerifyOTPRequest):
    otp_service = get_otp_service()
    if not otp_service.verify(phone=body.phone, otp=body.otp):
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")

    jwt_service = get_jwt_service()
    # farmer_id is the phone number — simple, unique, no external DB needed
    token = jwt_service.create_token(farmer_id=body.phone)
    return {"token": token, "farmer_id": body.phone}
```

- [ ] **Step 4: Register router in `bff/main.py`**

Add after the existing imports:

```python
from routers.auth import router as auth_router
```

Add after `app.mount(...)`:

```python
app.include_router(auth_router)
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd bff && pytest tests/test_auth.py -v
```

Expected: `3 passed`

- [ ] **Step 6: Commit**

```bash
git add bff/routers/auth.py bff/main.py bff/tests/test_auth.py
git commit -m "feat(bff): add OTP auth router"
```

---

## Task 10: Voice router

**Files:**
- Create: `bff/routers/voice.py`
- Create: `bff/tests/test_voice.py`
- Modify: `bff/main.py` — register voice router

- [ ] **Step 1: Write `bff/tests/test_voice.py`**

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_voice.py -v
```

Expected: `FAILED` — `404`

- [ ] **Step 3: Write `bff/routers/voice.py`**

```python
import os
import tempfile

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

from services.audio_store import get_audio_store
from services.backend_client import get_backend_client
from services.translation import get_translation_service
from services.tts import get_tts_service
from services.whisper import get_whisper_service

router = APIRouter(tags=["voice"])

SUPPORTED_LANGUAGES = {"hi", "te", "pa", "mr"}


async def _process_text_to_response(
    farmer_id: str,
    text_en: str,
    language: str,
    queued: bool = False,
) -> dict:
    """Shared pipeline: English text → agent → translate → TTS → response dict."""
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
    """Full voice pipeline: audio in → Whisper → translate → agent → TTS → audio out."""
    # Save uploaded audio to temp file
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
    """Text input pipeline: translate → agent → TTS → audio out."""
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
```

- [ ] **Step 4: Register router in `bff/main.py`**

Add import:
```python
from routers.voice import router as voice_router
```

Add after existing `include_router`:
```python
app.include_router(voice_router)
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd bff && pytest tests/test_voice.py -v
```

Expected: `2 passed`

- [ ] **Step 6: Commit**

```bash
git add bff/routers/voice.py bff/main.py bff/tests/test_voice.py
git commit -m "feat(bff): add voice pipeline router (voice/chat + text/chat)"
```

---

## Task 11: Sync router

**Files:**
- Create: `bff/routers/sync.py`
- Create: `bff/tests/test_sync.py`
- Modify: `bff/main.py` — register sync router

- [ ] **Step 1: Write `bff/tests/test_sync.py`**

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_sync.py -v
```

Expected: `FAILED` — `404`

- [ ] **Step 3: Write `bff/routers/sync.py`**

```python
from fastapi import APIRouter
from pydantic import BaseModel

from routers.voice import TextChatRequest, text_chat
from services.backend_client import get_backend_client

router = APIRouter(prefix="/sync", tags=["sync"])


class QueuedTextRequest(BaseModel):
    id: str
    text: str
    farmer_id: str
    language: str = "hi"
    queued_at: str


class SyncPushRequest(BaseModel):
    requests: list[QueuedTextRequest]


@router.post("/push")
async def sync_push(body: SyncPushRequest):
    """
    Process a batch of offline-queued text requests in order.
    Voice requests in the queue are sent directly to /voice/chat by the client.
    """
    results = []
    for req in body.requests:
        try:
            result = await text_chat(
                TextChatRequest(
                    farmer_id=req.farmer_id,
                    text=req.text,
                    language=req.language,
                    queued=True,
                )
            )
            results.append({"id": req.id, "success": True, "response": result})
        except Exception as e:
            results.append({"id": req.id, "success": False, "error": str(e)})

    return {"results": results}


@router.get("/pull/{farmer_id}")
async def sync_pull(farmer_id: str):
    """Return latest farmer profile + last 20 conversations for client sync."""
    backend = get_backend_client()
    farmer_profile = await backend.get_farmer(farmer_id=farmer_id)
    recent_conversations = await backend.get_history(farmer_id=farmer_id)
    return {
        "farmer_profile": farmer_profile,
        "recent_conversations": recent_conversations[:20],
    }
```

- [ ] **Step 4: Register router in `bff/main.py`**

Add import:
```python
from routers.sync import router as sync_router
```

Add after existing `include_router` calls:
```python
app.include_router(sync_router)
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd bff && pytest tests/test_sync.py -v
```

Expected: `3 passed`

- [ ] **Step 6: Commit**

```bash
git add bff/routers/sync.py bff/main.py bff/tests/test_sync.py
git commit -m "feat(bff): add offline sync router (push + pull)"
```

---

## Task 12: Notifications router

**Files:**
- Create: `bff/routers/notifications.py`
- Create: `bff/tests/test_notifications.py`
- Modify: `bff/main.py` — register notifications router

- [ ] **Step 1: Write `bff/tests/test_notifications.py`**

```python
import pytest
from unittest.mock import MagicMock, patch


@pytest.mark.asyncio
async def test_register_device_token_returns_200(client):
    mock_redis = MagicMock()

    with patch("routers.notifications.get_redis_client", return_value=mock_redis):
        response = await client.post(
            "/notifications/register",
            json={
                "farmer_id": "farmer-1",
                "device_token": "fcm-token-abc123",
                "platform": "fcm",
            },
        )

    assert response.status_code == 200
    assert response.json() == {"message": "Device registered"}


@pytest.mark.asyncio
async def test_register_stores_token_in_redis(client):
    mock_redis = MagicMock()

    with patch("routers.notifications.get_redis_client", return_value=mock_redis):
        await client.post(
            "/notifications/register",
            json={
                "farmer_id": "farmer-1",
                "device_token": "fcm-token-abc123",
                "platform": "fcm",
            },
        )

    mock_redis.hset.assert_called_once_with(
        "device_tokens:farmer-1",
        "fcm",
        "fcm-token-abc123",
    )
    mock_redis.expire.assert_called_once_with("device_tokens:farmer-1", 30 * 24 * 3600)


@pytest.mark.asyncio
async def test_register_rejects_invalid_platform(client):
    mock_redis = MagicMock()

    with patch("routers.notifications.get_redis_client", return_value=mock_redis):
        response = await client.post(
            "/notifications/register",
            json={
                "farmer_id": "farmer-1",
                "device_token": "token",
                "platform": "unknown-platform",
            },
        )

    assert response.status_code == 422
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd bff && pytest tests/test_notifications.py -v
```

Expected: `FAILED` — `404`

- [ ] **Step 3: Write `bff/routers/notifications.py`**

```python
from typing import Literal

import redis as redis_lib
from fastapi import APIRouter
from pydantic import BaseModel

from config import settings

router = APIRouter(prefix="/notifications", tags=["notifications"])

TOKEN_TTL_SECONDS = 30 * 24 * 3600  # 30 days


def get_redis_client():
    return redis_lib.from_url(settings.redis_url, decode_responses=True)


class RegisterDeviceRequest(BaseModel):
    farmer_id: str
    device_token: str
    platform: Literal["fcm", "apns"]


@router.post("/register")
def register_device(body: RegisterDeviceRequest):
    """Store device push token in Redis. Key: device_tokens:{farmer_id}."""
    redis = get_redis_client()
    redis.hset(f"device_tokens:{body.farmer_id}", body.platform, body.device_token)
    redis.expire(f"device_tokens:{body.farmer_id}", TOKEN_TTL_SECONDS)
    return {"message": "Device registered"}
```

- [ ] **Step 4: Register router in `bff/main.py`**

Add import:
```python
from routers.notifications import router as notifications_router
```

Add after existing `include_router` calls:
```python
app.include_router(notifications_router)
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd bff && pytest tests/test_notifications.py -v
```

Expected: `3 passed`

- [ ] **Step 6: Commit**

```bash
git add bff/routers/notifications.py bff/main.py bff/tests/test_notifications.py
git commit -m "feat(bff): add push notification device token registration"
```

---

## Task 13: Run full test suite

- [ ] **Step 1: Run all BFF tests**

```bash
cd bff && pytest tests/ -v
```

Expected output:
```
tests/test_health.py::test_health_returns_ok PASSED
tests/test_audio_store.py::test_save_returns_url_and_creates_file PASSED
tests/test_audio_store.py::test_save_creates_mp3_file PASSED
tests/test_audio_store.py::test_cleanup_removes_old_files PASSED
tests/test_audio_store.py::test_cleanup_keeps_recent_files PASSED
tests/test_backend_client.py::test_chat_sends_correct_payload PASSED
tests/test_backend_client.py::test_get_farmer_returns_profile PASSED
tests/test_backend_client.py::test_get_history_returns_list PASSED
tests/test_translation.py::test_detect_language_returns_code PASSED
tests/test_translation.py::test_translate_to_english PASSED
tests/test_translation.py::test_translate_from_english_to_hindi PASSED
tests/test_translation.py::test_skip_translation_when_already_english PASSED
tests/test_whisper.py::test_transcribe_returns_text_and_language PASSED
tests/test_whisper.py::test_transcribe_calls_whisper_with_correct_model PASSED
tests/test_tts.py::test_synthesize_returns_bytes PASSED
tests/test_tts.py::test_synthesize_uses_mp3_format PASSED
tests/test_jwt_service.py::test_create_and_decode_roundtrip PASSED
tests/test_jwt_service.py::test_decode_invalid_token_raises_401 PASSED
tests/test_jwt_service.py::test_decode_tampered_token_raises_401 PASSED
tests/test_jwt_service.py::test_expired_token_raises_401 PASSED
tests/test_otp_service.py::test_send_stores_otp_in_redis PASSED
tests/test_otp_service.py::test_send_sends_sms_via_twilio PASSED
tests/test_otp_service.py::test_verify_returns_true_for_correct_otp PASSED
tests/test_otp_service.py::test_verify_returns_false_for_wrong_otp PASSED
tests/test_otp_service.py::test_verify_returns_false_when_otp_expired PASSED
tests/test_auth.py::test_send_otp_returns_200 PASSED
tests/test_auth.py::test_verify_otp_returns_token_on_success PASSED
tests/test_auth.py::test_verify_otp_returns_401_on_wrong_otp PASSED
tests/test_voice.py::test_voice_chat_returns_expected_fields PASSED
tests/test_voice.py::test_text_chat_returns_expected_fields PASSED
tests/test_sync.py::test_sync_pull_returns_farmer_and_history PASSED
tests/test_sync.py::test_sync_push_processes_text_requests_in_order PASSED
tests/test_sync.py::test_sync_push_marks_failed_request_on_error PASSED
tests/test_notifications.py::test_register_device_token_returns_200 PASSED
tests/test_notifications.py::test_register_stores_token_in_redis PASSED
tests/test_notifications.py::test_register_rejects_invalid_platform PASSED

36 passed
```

If any test fails, debug before continuing.

---

## Task 14: Dockerfile + docker-compose + .env.example

**Files:**
- Create: `bff/Dockerfile`
- Modify: `docker-compose.yml`
- Modify: `.env.example`

- [ ] **Step 1: Write `bff/Dockerfile`**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /tmp/audio

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
```

- [ ] **Step 2: Add BFF service to `docker-compose.yml`**

Add the following service block after the `api` service, before `frontend`:

```yaml
  # ── BFF (Backend for Frontend) ──────────────────────────────
  bff:
    build:
      context: ./bff
      dockerfile: Dockerfile
    container_name: farmai-bff
    ports:
      - "8002:8002"
    env_file: .env
    environment:
      - BACKEND_URL=http://api:8000
      - REDIS_URL=redis://redis:6379
    depends_on:
      api:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8002/health"]
      interval: 30s
      retries: 3
```

- [ ] **Step 3: Add BFF env vars to `.env.example`**

Append to `.env.example`:

```bash
# ── BFF Service ─────────────────────────────────────────────
BFF_PORT=8002

# JWT (generate with: python -c "import secrets; print(secrets.token_hex(32))")
JWT_SECRET=your-32-char-secret-here

# OTP via Twilio (https://console.twilio.com)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token-here
TWILIO_PHONE_NUMBER=+1xxxxxxxxxx

# Google Cloud Translation (https://console.cloud.google.com)
GOOGLE_TRANSLATE_API_KEY=your-google-api-key-here

# Audio file storage (default is fine for dev)
AUDIO_DIR=/tmp/audio
AUDIO_TTL_HOURS=1
```

- [ ] **Step 4: Verify Docker build**

```bash
cd bff && docker build -t farmai-bff .
```

Expected: `Successfully built ...`

- [ ] **Step 5: Verify full stack starts**

```bash
cd .. && docker-compose up -d postgres redis api bff
docker-compose ps
```

Expected: `farmai-postgres`, `farmai-redis`, `farmai-api`, `farmai-bff` all show `healthy` or `running`.

- [ ] **Step 6: Verify BFF health in full stack**

```bash
curl http://localhost:8002/health
```

Expected: `{"status":"ok","service":"farm-ai-bff"}`

- [ ] **Step 7: Commit**

```bash
git add bff/Dockerfile docker-compose.yml .env.example
git commit -m "feat(bff): add Dockerfile, docker-compose service, env vars"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|---|---|
| BFF sits between clients and existing backend | Task 3 (backend_client), Task 10 (voice router) |
| Voice pipeline: STT → translate → agent → TTS | Task 5, 4, 3, 6, 10 |
| Phase 1 languages: hi, te, pa, mr | Task 10 (SUPPORTED_LANGUAGES constant) |
| Translation owned by BFF, backend receives English | Task 10 (`_process_text_to_response`) |
| OTP via Twilio, stored in Redis with TTL | Task 8 |
| JWT auth, 7-day expiry, phone = farmer_id | Task 7, 9 |
| POST /sync/push — batch text requests | Task 11 |
| GET /sync/pull — farmer profile + history | Task 11 |
| POST /notifications/register — FCM/APNs tokens in Redis, 30-day TTL | Task 12 |
| Audio files at /tmp/audio, 1-hour cleanup | Task 2, Task 1 (lifespan cleanup loop) |
| Dockerfile + docker-compose BFF service on 8002 | Task 14 |
| Backend untouched | Confirmed — no tasks modify `backend/` |

All spec requirements covered. No placeholders or TBDs in any task.
