"""
main.py — FarmAI FastAPI backend entry point.

================================================================================
📖 HOW THE BACKEND TIES EVERYTHING TOGETHER
================================================================================

This file is the glue:
  - Starts FastAPI web server
  - Mounts MCP client (connects to MCP server for tools)
  - Initializes RAG pipeline
  - Initializes farmer memory store
  - Exposes REST API endpoints for the frontend

The request flow for a chat message:
  1. Frontend sends POST /api/chat {farmer_id, message}
  2. This handler loads farmer context from memory
  3. Calls run_agent(query, farmer_context) → LangGraph supervisor
  4. Supervisor routes to specialist → specialist calls MCP tools + RAG
  5. Response flows back → saved to history → returned to frontend

This is a complete "agentic application" pattern.
================================================================================
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from config import settings
from agents.supervisor import run_agent
from memory.store import memory_store
from rag.ingestion import seed_sample_data

logging.basicConfig(level=getattr(logging, settings.log_level))
logger = logging.getLogger(__name__)


# ── App Lifecycle ─────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup and shutdown logic.
    'yield' separates startup (before) from shutdown (after).
    """
    # Startup
    logger.info("🌱 FarmAI Backend starting up...")
    try:
        await memory_store.init()
        logger.info("✅ Database connection ready")
    except Exception as e:
        logger.warning(f"⚠️  Database not available (demo mode): {e}")

    yield  # App runs here

    # Shutdown
    await memory_store.close()
    logger.info("🛑 FarmAI Backend shut down")


# ── FastAPI App ───────────────────────────────────────────────────────────────
app = FastAPI(
    title="FarmAI API",
    description="AI-powered agricultural advisory platform for Indian farmers",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow the frontend to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request/Response Models ───────────────────────────────────────────────────
class ChatRequest(BaseModel):
    farmer_id: str = "demo-farmer"
    message: str
    image_base64: Optional[str] = None
    thread_id: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    agent_used: str
    farmer_id: str


class FarmerCreate(BaseModel):
    name: str
    phone: Optional[str] = None
    location: Optional[str] = None
    state: Optional[str] = None
    land_acres: float = 5.0
    current_crops: list[str] = []
    irrigation_type: str = "flood"
    category: str = "small"


class IngestRequest(BaseModel):
    collection: str  # "crop_guides" | "pest_library" | "govt_schemes"
    data_dir: Optional[str] = None
    reset: bool = False


# ── API Endpoints ─────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {
        "name": "FarmAI API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
        "endpoints": {
            "chat": "POST /api/chat",
            "farmer": "GET/POST /api/farmer/{id}",
            "ingest": "POST /api/ingest",
            "health": "GET /health",
        }
    }


@app.get("/health")
async def health():
    return {"status": "healthy", "environment": settings.environment}


@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main chat endpoint — routes farmer queries through the multi-agent system.

    📖 NOTE: This is the core endpoint that brings MCP + RAG + Agents together.
    1. Load farmer context from memory
    2. Run through LangGraph supervisor + specialist agents
    3. Save interaction to history
    4. Return response
    """
    logger.info(f"Chat request: farmer={request.farmer_id}, message={request.message[:80]}")

    # Load farmer context (for personalized responses)
    try:
        farmer_context = await memory_store.get_farmer_dict(request.farmer_id)
    except Exception:
        # Demo mode: use default context if DB not available
        farmer_context = {
            "name": "Demo Farmer",
            "location": "Hyderabad, Telangana",
            "state": "telangana",
            "land_acres": 5,
            "current_crops": ["tomato", "cotton"],
            "irrigation_type": "drip",
            "category": "small",
        }

    # Run multi-agent system
    try:
        result = await run_agent(
            query=request.message,
            farmer_id=request.farmer_id,
            farmer_context=farmer_context,
            image_data=request.image_base64,
            thread_id=request.thread_id or request.farmer_id,
        )
    except Exception as e:
        logger.error(f"Agent error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Agent processing failed: {str(e)}")

    # Save to history (async, fire-and-forget)
    try:
        await memory_store.save_interaction(
            farmer_id=request.farmer_id,
            query=request.message,
            response=result["final_response"],
            agent_used=result.get("agent_used", "unknown"),
        )
    except Exception as e:
        logger.warning(f"Failed to save history: {e}")

    return ChatResponse(
        response=result["final_response"],
        agent_used=result.get("agent_used", "unknown"),
        farmer_id=request.farmer_id,
    )


@app.post("/api/farmer", response_model=dict)
async def create_farmer(farmer: FarmerCreate):
    """Create a new farmer profile."""
    try:
        result = await memory_store.create_farmer(farmer.model_dump())
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/farmer/{farmer_id}")
async def get_farmer(farmer_id: str):
    """Get farmer profile and recent history."""
    try:
        farmer = await memory_store.get_farmer(farmer_id)
        if not farmer:
            raise HTTPException(status_code=404, detail="Farmer not found")
        history = await memory_store.get_recent_history(farmer_id, limit=10)
        return {"farmer": farmer, "recent_history": history}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/ingest")
async def ingest_documents(request: IngestRequest):
    """
    Trigger document ingestion into the RAG vector store.

    📖 NOTE: Call this endpoint to:
    1. Seed initial knowledge base (call once on setup)
    2. Add new documents (whenever you add new PDFs)
    3. Reset and re-ingest (when documents are updated)
    """
    import os
    from rag.ingestion import ingest_knowledge_base

    # Default data directory
    data_dir = request.data_dir or os.path.join(
        os.path.dirname(__file__), "rag", "data", request.collection
    )

    try:
        result = await ingest_knowledge_base(
            data_dir=data_dir,
            collection=request.collection,
            reset=request.reset,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/seed")
async def seed_knowledge_base():
    """Seed the knowledge base with sample agricultural documents."""
    try:
        results = await seed_sample_data()
        return {"status": "success", "results": results}
    except Exception as e:
        logger.error(f"Seed failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/history/{farmer_id}")
async def get_history(farmer_id: str, limit: int = 20):
    """Get conversation history for a farmer."""
    try:
        history = await memory_store.get_recent_history(farmer_id, limit=limit)
        return {"farmer_id": farmer_id, "history": history, "count": len(history)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
