"""
server.py — The FarmAI MCP Server.

================================================================================
📖 DEEP DIVE: What is MCP and why does this file matter?
================================================================================

MCP (Model Context Protocol) is an open standard (created by Anthropic, 2024)
that defines how AI models communicate with external tools.

Think of it like this:
  - HTTP defines how browsers talk to web servers
  - USB defines how devices talk to computers
  - MCP defines how AI models talk to tools

WITHOUT MCP (old way):
    Every app hardcoded tool definitions into the API call:
    ```python
    client.messages.create(
        tools=[{"name": "weather", "input_schema": {...}}],  # You define this EVERY TIME
        ...
    )
    ```
    If you had 10 apps, you wrote the tool schema 10 times.
    Changing the tool = updating 10 apps.

WITH MCP (new way):
    You define the tool ONCE in an MCP server.
    ANY AI client automatically discovers and calls it.
    Claude Desktop, your custom app, any future app = all get the tools for free.

HOW IT WORKS (the 5-step flow):
    1. This server starts and registers tools (weather, prices, soil, schemes)
    2. An AI client (Claude Desktop or your FastAPI app) connects via SSE
    3. Client sends: "list_tools" → Server responds with all tool schemas
    4. Claude sees the schemas, decides which tool to call for a query
    5. Client sends: "call_tool(weather, {location: 'Hyderabad'})"
    6. Server runs the Python function → returns JSON
    7. Claude reads the JSON and includes it in its response

THE TRANSPORT:
    We use SSE (Server-Sent Events) transport.
    SSE = one-way streaming from server to client (like a live news feed).
    MCP uses SSE for the server to push tool responses to the AI client.
    The client sends requests via HTTP POST.

    Alternative transport: stdio (for local/CLI usage)
    SSE is better for web/production deployments.
================================================================================
"""

import asyncio
import logging
from mcp.server.fastmcp import FastMCP

# Import our tool implementations
from tools.weather_tool import get_weather_forecast
from tools.market_price_tool import get_mandi_prices
from tools.soil_tool import get_soil_recommendations
from tools.scheme_lookup_tool import find_eligible_schemes

# ── Initialize FastMCP ───────────────────────────────────────────────────────
# FastMCP is a high-level wrapper over the MCP Python SDK.
# It handles:
#   - SSE transport setup
#   - Tool schema generation (reads Python type hints → JSON schema)
#   - Request routing
#   - Error handling
#
# The string "FarmAI MCP Server" is the server's NAME.
# AI clients see this name when they connect.
mcp = FastMCP("FarmAI MCP Server")

logger = logging.getLogger(__name__)


# ============================================================================
# TOOL REGISTRATION
# ============================================================================
# Each @mcp.tool() decorator does 3 things:
#   1. Reads the function's type hints → generates JSON schema for the AI
#   2. Reads the docstring → this becomes the tool's "description" the AI reads
#   3. Registers the function as callable by any MCP client
#
# The AI (Claude) reads the docstring to decide WHEN to call each tool.
# Docstrings are NOT just for human developers — they're AI instructions!
# Write them clearly and include: what it does, when to use it, what it returns.
# ============================================================================


@mcp.tool()
async def weather_forecast(location: str, days: int = 7) -> dict:
    """
    Get weather forecast for a farm location in India.

    Use this tool when the farmer asks about:
    - Weather conditions for their region
    - Whether to irrigate or not (check rainfall forecast)
    - Best time for pesticide/fertilizer spraying
    - Risk of pest outbreaks (humidity + temperature driven)
    - Harvest timing (avoid rain during harvest)

    Args:
        location: City, district, or region name (e.g., "Hyderabad",
                  "Vidarbha", "Nashik", "Amritsar")
        days: Number of forecast days (1-7, default 7)

    Returns:
        dict with daily forecasts, rainfall totals, humidity,
        and farming-specific advice (irrigation need, spray windows, harvest risk)
    """
    logger.info(f"MCP tool called: weather_forecast(location={location}, days={days})")
    return await get_weather_forecast(location, days)


@mcp.tool()
async def mandi_prices(crop: str, state: str) -> dict:
    """
    Fetch latest market/mandi prices for a crop in an Indian state.

    Use this tool when the farmer asks about:
    - Current price of their crop
    - Whether to sell now or wait
    - Which mandi to take their produce to
    - How current prices compare to MSP (Minimum Support Price)
    - Price trends over the last 30 days

    Args:
        crop: Crop name — wheat, rice, cotton, tomato, soybean, maize
        state: Indian state — telangana, maharashtra, punjab, karnataka, etc.

    Returns:
        dict with current prices, per-mandi comparison, 30-day trend,
        MSP comparison, and a selling recommendation
    """
    logger.info(f"MCP tool called: mandi_prices(crop={crop}, state={state})")
    return await get_mandi_prices(crop, state)


@mcp.tool()
async def soil_analysis(lat: float, lon: float) -> dict:
    """
    Get soil type, pH, NPK levels, and fertilizer recommendations for GPS coordinates.

    Use this tool when the farmer asks about:
    - What type of soil they have
    - Which crops are suitable for their land
    - Fertilizer recommendations (how much urea, DAP, potash)
    - Micronutrient deficiencies (zinc, boron, etc.)
    - Soil pH and whether amendment is needed

    Args:
        lat: Latitude in decimal degrees (e.g., 17.3850 for Hyderabad)
        lon: Longitude in decimal degrees (e.g., 78.4867 for Hyderabad)

    Returns:
        dict with soil type, pH interpretation, NPK status,
        fertilizer product recommendations with doses, and suitable crops
    """
    logger.info(f"MCP tool called: soil_analysis(lat={lat}, lon={lon})")
    return await get_soil_recommendations(lat, lon)


@mcp.tool()
async def government_schemes(
    state: str,
    crop: str,
    farmer_category: str
) -> dict:
    """
    Find government schemes, subsidies, and support programs a farmer is eligible for.

    Use this tool when the farmer asks about:
    - Government schemes or subsidies available to them
    - How to get financial support from the government
    - Crop insurance options
    - Equipment subsidies or loans
    - PM-KISAN, PMFBY, or KCC eligibility

    Args:
        state: Farmer's state (telangana, maharashtra, punjab, etc.)
        crop: Primary crop (wheat, rice, cotton, etc.)
        farmer_category: Land holding size —
            "small" (less than 2 acres),
            "marginal" (2-5 acres),
            "large" (more than 5 acres)

    Returns:
        List of eligible schemes with benefits, required documents,
        application process, and priority ranking
    """
    logger.info(f"MCP tool called: government_schemes(state={state}, crop={crop}, category={farmer_category})")
    return await find_eligible_schemes(state, crop, farmer_category)


# ============================================================================
# MCP SERVER STARTUP
# ============================================================================

if __name__ == "__main__":
    """
    Run the MCP server directly.

    Command:  python backend/mcp/server.py
    The server starts on port 8001 (configured in .env).

    To TEST your MCP server with the MCP Inspector tool:
        npx @modelcontextprotocol/inspector http://localhost:8001/sse

    To CONNECT from Claude Desktop, add to ~/Library/Application Support/Claude/claude_desktop_config.json:
    {
        "mcpServers": {
            "farmai": {
                "url": "http://localhost:8001/sse",
                "transport": "sse"
            }
        }
    }

    After that, Claude Desktop will have all 4 tools available in EVERY conversation!
    You'll see "FarmAI MCP Server" in the tools panel.
    """
    import os
    port = int(os.getenv("MCP_SERVER_PORT", "8001"))

    print(f"""
╔══════════════════════════════════════════════════════╗
║            FarmAI MCP Server Starting                ║
║──────────────────────────────────────────────────────║
║  Transport: SSE (Server-Sent Events)                 ║
║  Port: {port}                                          ║
║  Endpoint: http://localhost:{port}/sse                 ║
║──────────────────────────────────────────────────────║
║  Registered Tools:                                   ║
║  • weather_forecast(location, days)                  ║
║  • mandi_prices(crop, state)                         ║
║  • soil_analysis(lat, lon)                           ║
║  • government_schemes(state, crop, category)         ║
║──────────────────────────────────────────────────────║
║  Test: npx @modelcontextprotocol/inspector           ║
║        http://localhost:{port}/sse                     ║
╚══════════════════════════════════════════════════════╝
    """)

    mcp.run(transport="sse", port=port)
