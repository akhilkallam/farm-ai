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
        try:
            cutoff = time.time() - (settings.audio_ttl_hours * 3600)
            for fname in os.listdir(settings.audio_dir):
                fpath = os.path.join(settings.audio_dir, fname)
                if os.path.isfile(fpath) and os.path.getmtime(fpath) < cutoff:
                    os.remove(fpath)
                    logger.debug("Deleted old audio file: %s", fname)
        except Exception as e:
            logger.warning("Audio cleanup error: %s", e)
        await asyncio.sleep(3600)


@asynccontextmanager
async def lifespan(app: FastAPI):
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

os.makedirs(settings.audio_dir, exist_ok=True)
app.mount("/audio", StaticFiles(directory=settings.audio_dir), name="audio")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "farm-ai-bff"}
