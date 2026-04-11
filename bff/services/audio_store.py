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
