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
