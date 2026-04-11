from __future__ import annotations

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
    """Process a batch of offline-queued text requests in order."""
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
