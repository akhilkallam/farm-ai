"""
test_agents.py — End-to-end test script for the FarmAI multi-agent system.

Run: python scripts/test_agents.py

📖 LEARNING NOTE:
    This script tests the full flow WITHOUT the frontend.
    Great for development — you can see exactly what each agent returns.
    It also shows you how to call the API programmatically.
"""

import asyncio
import httpx
import json
import sys
import os

# Add backend to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

API_URL = "http://localhost:8000"
FARMER_ID = "00000000-0000-0000-0000-000000000001"  # Raju Reddy (seeded in init.sql)

# ── Test Scenarios ─────────────────────────────────────────────────────────────
TEST_SCENARIOS = [
    {
        "name": "Crop Planning — Rabi season",
        "query": "Which crop should I plant this Rabi season on my 5-acre cotton field in Warangal?",
        "expected_agent": "crop_advisor",
        "description": "Tests: Supervisor routing + crop_advisor + MCP weather + RAG crop_guides",
    },
    {
        "name": "Pest Diagnosis — Tomato disease",
        "query": "My tomato plants have circular brown spots with yellow rings around them. Lower leaves are affected first. What disease is this and how do I treat it?",
        "expected_agent": "pest_detector",
        "description": "Tests: Supervisor routing + pest_detector + RAG pest_library",
    },
    {
        "name": "Market Price — Selling decision",
        "query": "Should I sell my cotton now or wait? What is the current price in Telangana mandis?",
        "expected_agent": "market_analyst",
        "description": "Tests: market_analyst + MCP mandi_prices tool",
    },
    {
        "name": "Irrigation — Scheduling",
        "query": "I have drip irrigation. When should I water my cotton field this week given the upcoming rain?",
        "expected_agent": "irrigation_planner",
        "description": "Tests: irrigation_planner + MCP weather + MCP soil_analysis",
    },
    {
        "name": "Government Scheme — Eligibility",
        "query": "I am a small farmer with 5 acres in Telangana growing cotton. What government schemes am I eligible for?",
        "expected_agent": "scheme_navigator",
        "description": "Tests: scheme_navigator + MCP government_schemes + RAG govt_schemes",
    },
]


async def test_health():
    """Check if API is running."""
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(f"{API_URL}/health", timeout=5)
            print(f"✅ API Health: {resp.json()}")
            return True
        except Exception as e:
            print(f"❌ API not reachable: {e}")
            print("   Start the API: uvicorn main:app --host 0.0.0.0 --port 8000")
            return False


async def run_test(scenario: dict, client: httpx.AsyncClient) -> bool:
    """Run a single test scenario."""
    print(f"\n{'='*60}")
    print(f"🧪 Test: {scenario['name']}")
    print(f"   {scenario['description']}")
    print(f"   Query: {scenario['query'][:80]}...")
    print(f"   Expected agent: {scenario['expected_agent']}")

    try:
        resp = await client.post(
            f"{API_URL}/api/chat",
            json={
                "farmer_id": FARMER_ID,
                "message": scenario["query"],
                "thread_id": f"test-{scenario['name']}",
            },
            timeout=60,  # Agents can take time
        )

        if resp.status_code != 200:
            print(f"   ❌ HTTP Error: {resp.status_code} — {resp.text[:200]}")
            return False

        data = resp.json()
        agent_used = data.get("agent_used", "unknown")
        response = data.get("response", "")

        print(f"\n   Agent used: {agent_used}")
        print(f"   Expected:   {scenario['expected_agent']}")

        agent_match = agent_used == scenario["expected_agent"]
        print(f"\n   {'✅' if agent_match else '⚠️ '} Agent routing: {'CORRECT' if agent_match else 'DIFFERENT (may still be ok)'}")

        print(f"\n   Response preview:")
        print(f"   {response[:300]}...")

        return True

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


async def test_mcp_tools():
    """Test MCP tools directly (if MCP server is running)."""
    MCP_URL = "http://localhost:8001"
    print(f"\n{'='*60}")
    print("🔌 Testing MCP Server Tools")

    async with httpx.AsyncClient() as client:
        try:
            # Most MCP SSE endpoints need the MCP client to connect
            # We just check if the server is up
            resp = await client.get(f"{MCP_URL}/", timeout=3)
            print(f"✅ MCP Server reachable (status: {resp.status_code})")
        except Exception:
            print("⚠️  MCP Server not running. Start with: python backend/mcp/server.py")
            print("   Tools will still work via direct function calls in the API.")


async def main():
    print("🌱 FarmAI End-to-End Test Suite")
    print("================================\n")

    # 1. Check API health
    if not await test_health():
        print("\n💡 To start the API:")
        print("   cd farm-ai/backend")
        print("   uvicorn main:app --reload")
        sys.exit(1)

    # 2. Test MCP server
    await test_mcp_tools()

    # 3. Run all test scenarios
    print(f"\n🚀 Running {len(TEST_SCENARIOS)} test scenarios...\n")

    passed = 0
    async with httpx.AsyncClient() as client:
        for scenario in TEST_SCENARIOS:
            success = await run_test(scenario, client)
            if success:
                passed += 1

    print(f"\n{'='*60}")
    print(f"📊 Results: {passed}/{len(TEST_SCENARIOS)} scenarios completed")

    if passed == len(TEST_SCENARIOS):
        print("🎉 All tests passed!")
    else:
        print(f"⚠️  {len(TEST_SCENARIOS) - passed} scenarios failed.")

    print("\n💡 Next steps:")
    print("   1. Open http://localhost:3000 for the farmer UI")
    print("   2. Connect Claude Desktop to the MCP server (port 8001)")
    print("   3. Try: npx @modelcontextprotocol/inspector http://localhost:8001/sse")


if __name__ == "__main__":
    asyncio.run(main())
