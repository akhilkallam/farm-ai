# 🌱 FarmAI — Agricultural Intelligence Platform

> A full-stack GenAI demo showing MCP, RAG, and Multi-Agent patterns
> built for learning and production use.

## What You'll Learn

| Pattern | Where | Concept |
|---|---|---|
| **MCP** | `backend/mcp/server.py` | Expose tools any AI can call |
| **RAG** | `backend/rag/` | Search real docs before answering |
| **Multi-Agent** | `backend/agents/supervisor.py` | Route queries to specialist AIs |
| **Memory** | `backend/memory/store.py` | Persist farmer context across sessions |
| **Structured Output** | All agents | JSON-schema forced responses |

---

## Quick Start (5 minutes)

```bash
# 1. Configure environment
cp .env.example .env
# Add your ANTHROPIC_API_KEY in .env

# 2. Start databases
docker-compose up postgres redis -d

# 3. Install Python dependencies
cd backend && pip install -r requirements.txt

# 4. Start the MCP server (Terminal 1)
python backend/mcp/server.py
# → Listening on http://localhost:8001/sse

# 5. Start the API server (Terminal 2)
uvicorn backend.main:app --reload --port 8000
# → API at http://localhost:8000/docs

# 6. Test the agents
python scripts/test_agents.py

# 7. Open the frontend (Terminal 3)
cd frontend && npm install && npm run dev
# → UI at http://localhost:3000
```

---

## MCP — The Key Concept

```
                  ┌─────────────────────────────┐
                  │      MCP SERVER (port 8001)  │
                  │                             │
Claude Desktop ──►│  weather_forecast()         │──► OpenWeather API
  OR              │  mandi_prices()             │──► AgMarkNet
Your App     ──►│  soil_analysis()            │──► Soil DB
  OR              │  government_schemes()       │──► Scheme DB
Claude API   ──►│                             │
                  └─────────────────────────────┘

ANY AI client connects via: http://localhost:8001/sse
```

**Connect Claude Desktop to these tools:**

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "farmai": {
      "url": "http://localhost:8001/sse",
      "transport": "sse"
    }
  }
}
```

Then in Claude Desktop, you'll see 4 new tools available in every conversation!

**Test MCP with the Inspector:**
```bash
npx @modelcontextprotocol/inspector http://localhost:8001/sse
```

---

## Architecture

```
Farmer Query
     │
     ▼
FastAPI /api/chat
     │
     ▼
LangGraph Supervisor (Claude decides routing)
     │
     ├──► crop_advisor → RAG(crop_guides) + MCP(weather, soil)
     ├──► pest_detector → RAG(pest_library) + Vision
     ├──► market_analyst → MCP(mandi_prices, weather)
     ├──► irrigation_planner → MCP(weather, soil) + RAG(crop_guides)
     └──► scheme_navigator → MCP(govt_schemes) + RAG(govt_schemes)
                                           │
                                           ▼
                              Farmer Memory (PostgreSQL)
```

---

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/chat` | POST | Main chat — runs multi-agent system |
| `/api/farmer` | POST | Create farmer profile |
| `/api/farmer/{id}` | GET | Get farmer + history |
| `/api/seed` | POST | Seed knowledge base with sample docs |
| `/health` | GET | Health check |
| `/docs` | GET | Swagger API documentation |

---

## Adding Your Own MCP Tools

1. Create `backend/mcp/tools/your_tool.py`
2. Add the async function
3. Register in `backend/mcp/server.py`:
```python
@mcp.tool()
async def your_tool(param: str) -> dict:
    """Clear docstring — the AI reads this to know when to call your tool."""
    return await your_implementation(param)
```
4. Restart the MCP server — all clients auto-discover the new tool!

---

## Adding Knowledge to RAG

1. Drop PDF/markdown files into `backend/rag/data/<collection>/`
2. Call: `POST /api/ingest {"collection": "crop_guides"}`
3. Documents are chunked, embedded, and stored in pgvector
4. Agents now answer with your new documents as context

---

Built with: Claude (Anthropic) • LangGraph • FastMCP • pgvector • FastAPI • React
