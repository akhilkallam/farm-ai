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
