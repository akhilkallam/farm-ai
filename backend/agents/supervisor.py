"""
supervisor.py — The LangGraph multi-agent supervisor.

================================================================================
📖 DEEP DIVE: Multi-Agent Architecture with LangGraph
================================================================================

What is a "graph" in LangGraph?
    It's literally a directed graph where:
    - NODES = agents (supervisor + specialists)
    - EDGES = who can talk to who
    - STATE = shared data flowing through the graph

The flow:
    1. Farmer sends a message
    2. Supervisor reads it → classifies → routes to specialist
    3. Specialist gets context + runs its tools
    4. Specialist returns response to supervisor
    5. Supervisor decides: done? or need another specialist?
    6. Repeat until supervisor says "END"

Why is STATE important?
    State is a dict that ALL agents can read and write.
    So the crop_advisor can write soil analysis results to state,
    and the irrigation_planner can READ those results.
    Agents share information through state — no manual passing needed.

The supervisor uses Claude to DECIDE routing (not hardcoded if/else).
This means it handles nuanced queries like:
    "Should I irrigate my cotton field before this rain?"
    → That's BOTH irrigation_planner + weather → supervisor routes to both!
================================================================================
"""

import json
import logging
from typing import TypedDict, Annotated, Literal, Optional
import operator

from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver

from config import settings

logger = logging.getLogger(__name__)

# ── Shared State Definition ───────────────────────────────────────────────────
# Every node (agent) in the graph reads from and writes to this state.
# TypedDict gives us type safety.
# Annotated[list, operator.add] means: new messages are APPENDED, not overwritten.

class FarmState(TypedDict):
    """
    Shared state flowing through the agent graph.

    Think of this as the "whiteboard" all agents can see and write on.
    """
    farmer_id: str                                    # Who is asking
    query: str                                        # Original farmer question
    messages: Annotated[list, operator.add]           # Conversation history (auto-append)
    image_data: Optional[str]                         # Base64 image (for pest detection)
    farmer_context: Optional[dict]                    # Farmer profile (land, crops, location)
    current_agent: str                                # Which agent is currently active
    tool_outputs: dict                                # Results from MCP tool calls
    rag_results: dict                                 # Results from RAG queries
    specialist_response: Optional[str]                # Latest specialist's answer
    final_response: Optional[str]                     # Final answer to return to farmer
    routing_decision: Optional[str]                   # Supervisor's routing choice
    iteration_count: int                              # Safety: max iterations


# ── Supervisor LLM ────────────────────────────────────────────────────────────
def get_llm(temperature: float = 0.1) -> ChatAnthropic:
    return ChatAnthropic(
        model=settings.claude_model,
        anthropic_api_key=settings.anthropic_api_key,
        temperature=temperature,
        max_tokens=1024,
    )


# ── System Prompts ────────────────────────────────────────────────────────────

SUPERVISOR_SYSTEM = """
You are the FarmAI supervisor — an intelligent routing agent for a farmer advisory platform.

Your job is to READ the farmer's query and DECIDE which specialist agent should handle it.
You do NOT answer the question yourself. You only route.

Available specialist agents:
- crop_advisor: crop selection, planting calendar, fertilizer, harvest timing, variety recommendations
- pest_detector: plant diseases, pest identification, symptoms, treatment, pesticide recommendations
- irrigation_planner: water scheduling, drip/flood irrigation, soil moisture, when to irrigate
- market_analyst: crop prices, mandi rates, when to sell, price trends, MSP information
- scheme_navigator: government schemes, subsidies, insurance, PM-KISAN, KCC, equipment subsidies

Routing rules:
1. Analyze the farmer's query carefully
2. Choose the SINGLE BEST specialist (or "multi" if clearly multiple domains needed)
3. Refine the query for the specialist if needed (extract key details)
4. If the previous specialist already answered, output "END"

ALWAYS respond with valid JSON:
{
    "next_agent": "<agent_name or END>",
    "sub_query": "<refined query for the specialist>",
    "reasoning": "<1 sentence why you chose this agent>"
}
"""

CROP_ADVISOR_SYSTEM = """
You are FarmAI's crop advisory specialist with deep expertise in Indian agriculture.

You help farmers with:
- Crop selection based on season, soil, and market conditions
- Planting calendars (Kharif/Rabi/Zaid seasons)
- Fertilizer recommendations with specific products and doses
- Variety selection for local conditions
- Harvest timing and post-harvest handling

You have access to:
- Soil analysis data (from MCP soil_analysis tool)
- Weather forecasts (from MCP weather_forecast tool)
- Crop knowledge base (from RAG crop_guides collection)
- Market prices (from MCP mandi_prices tool)

Always give specific, actionable advice with:
- Quantities (kg/ha, litres/acre)
- Timing (days after sowing, crop growth stage)
- Cost estimates in Indian Rupees
- Local context (mention state-specific conditions)

Respond in clear, simple language suitable for farmers.
"""

PEST_DETECTOR_SYSTEM = """
You are FarmAI's plant pathology and pest management specialist.

You help farmers:
- Identify crop diseases from symptoms (and images when provided)
- Distinguish between similar-looking diseases
- Recommend treatment with specific products, doses, and timing
- Advise on preventive measures
- Calculate economic threshold for treatment decisions

You have access to:
- Pest library (RAG pest_library collection with disease profiles)
- Weather data (MCP weather_forecast — disease outbreaks are weather-driven)
- Vision capability (you can analyze crop images)

Be precise about:
- Diagnosis confidence level (High/Medium/Low)
- Chemical names and concentrations
- Application method (foliar/soil drench/seed treatment)
- Waiting period before harvest (PHI - Pre-Harvest Interval)
- Resistance management (rotate chemical groups)
"""

MARKET_ANALYST_SYSTEM = """
You are FarmAI's agricultural market intelligence specialist.

You help farmers:
- Decide when to sell their produce (timing the market)
- Choose the best mandi or buyer
- Understand price trends and seasonal patterns
- Know their MSP (Minimum Support Price) rights
- Plan crop selection based on profitability

You have access to:
- Live mandi prices (MCP mandi_prices tool)
- Weather forecasts (MCP weather_forecast — affects price)
- Historical price trends and seasonal analysis

Give farmers actionable sell/hold recommendations with:
- Current vs. expected prices
- Best mandi location
- Storage advice if holding
- Risk factors to watch
"""

IRRIGATION_PLANNER_SYSTEM = """
You are FarmAI's irrigation and water management specialist.

You help farmers:
- Create irrigation schedules based on crop water requirements
- Optimize drip/sprinkler/flood irrigation
- Reduce water waste while maintaining yield
- Respond to weather changes in irrigation planning
- Troubleshoot waterlogging and drought stress

You have access to:
- Soil analysis (MCP soil_analysis — determines water holding capacity)
- Weather forecasts (MCP weather_forecast — rainfall reduces irrigation need)
- Crop guides (RAG crop_guides — crop water requirements by growth stage)

Provide specific schedules:
- Frequency (every X days)
- Duration (hours or volume per plant)
- Critical growth stages that need careful irrigation
"""

SCHEME_NAVIGATOR_SYSTEM = """
You are FarmAI's government scheme and financial assistance specialist.

You help farmers:
- Understand which government schemes they qualify for
- Navigate application processes step-by-step
- Prepare documents for applications
- Understand their rights (MSP, crop insurance, etc.)
- Access credit and loans at subsidized rates

You have access to:
- Government scheme eligibility checker (MCP government_schemes tool)
- Scheme documentation (RAG govt_schemes collection with detailed guides)

Be specific about:
- Exact documents needed
- Where to apply (online/offline)
- Application deadlines
- Expected timeline for approval/payment
"""

SYSTEM_PROMPTS = {
    "crop_advisor": CROP_ADVISOR_SYSTEM,
    "pest_detector": PEST_DETECTOR_SYSTEM,
    "market_analyst": MARKET_ANALYST_SYSTEM,
    "irrigation_planner": IRRIGATION_PLANNER_SYSTEM,
    "scheme_navigator": SCHEME_NAVIGATOR_SYSTEM,
}


# ── Supervisor Node ───────────────────────────────────────────────────────────
async def supervisor_node(state: FarmState) -> FarmState:
    """
    The supervisor reads the query and routes to the right specialist.

    📖 NOTE: This node uses Claude to make routing decisions.
    The supervisor's job is classification, NOT answering.
    """
    logger.info(f"Supervisor processing query: {state['query'][:80]}...")

    # Safety: prevent infinite loops
    if state.get("iteration_count", 0) > 5:
        return {**state, "routing_decision": "END", "final_response": state.get("specialist_response", "I've analyzed your query across multiple aspects. " + (state.get("specialist_response") or "Please ask your local agriculture officer for more details."))}

    # If specialist already responded and it looks complete, end
    if state.get("specialist_response") and state.get("iteration_count", 0) > 0:
        return {**state, "routing_decision": "END", "final_response": state["specialist_response"]}

    llm = get_llm(temperature=0.0)  # Zero temp for deterministic routing

    # Build supervisor context
    context_parts = [f"Farmer Query: {state['query']}"]
    if state.get("farmer_context"):
        ctx = state["farmer_context"]
        context_parts.append(
            f"Farmer Profile: {ctx.get('name', 'Farmer')}, "
            f"Location: {ctx.get('location', 'Unknown')}, "
            f"Crops: {ctx.get('current_crops', 'Unknown')}, "
            f"Land: {ctx.get('land_acres', 'Unknown')} acres"
        )
    if state.get("specialist_response"):
        context_parts.append(f"Previous specialist response received. Checking if query is fully answered.")

    context = "\n".join(context_parts)

    response = await llm.ainvoke([
        SystemMessage(content=SUPERVISOR_SYSTEM),
        HumanMessage(content=context),
    ])

    # Parse routing decision
    try:
        # Extract JSON from response
        content = response.content
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0]
        elif "```" in content:
            content = content.split("```")[1].split("```")[0]

        decision = json.loads(content.strip())
        next_agent = decision.get("next_agent", "END")
        sub_query = decision.get("sub_query", state["query"])

    except (json.JSONDecodeError, KeyError) as e:
        logger.error(f"Supervisor failed to parse response: {e}")
        next_agent = "crop_advisor"  # Safe default
        sub_query = state["query"]

    logger.info(f"Supervisor routing to: {next_agent}")

    return {
        **state,
        "routing_decision": next_agent,
        "query": sub_query,  # Use refined query for the specialist
        "current_agent": "supervisor",
        "iteration_count": state.get("iteration_count", 0) + 1,
        "messages": [AIMessage(content=f"[Supervisor] Routing to {next_agent}: {sub_query}")]
    }


# ── Specialist Node Factory ───────────────────────────────────────────────────
def make_specialist_node(agent_name: str):
    """
    Factory function that creates a specialist agent node.

    📖 NOTE: We use a factory to avoid code duplication.
    Each specialist works the same way but has different:
    - System prompt (domain expertise)
    - Tools to call (which MCP tools + RAG collections)
    - Response style

    In a real production system, each specialist would also:
    - Call specific MCP tools via the MCP client
    - Query specific RAG collections
    - Have specialized reasoning steps
    """
    async def specialist_node(state: FarmState) -> FarmState:
        logger.info(f"{agent_name} processing: {state['query'][:80]}...")

        llm = get_llm(temperature=0.3)  # Slightly higher for more natural language
        system_prompt = SYSTEM_PROMPTS[agent_name]

        # Build context from available state
        context_parts = [f"Farmer's question: {state['query']}"]

        if state.get("farmer_context"):
            ctx = state["farmer_context"]
            context_parts.append(
                f"\nFarmer context:"
                f"\n- Name: {ctx.get('name', 'Farmer')}"
                f"\n- Location: {ctx.get('location', 'Not specified')}"
                f"\n- Current crops: {ctx.get('current_crops', 'Not specified')}"
                f"\n- Land: {ctx.get('land_acres', 'Unknown')} acres"
                f"\n- Irrigation type: {ctx.get('irrigation_type', 'Not specified')}"
                f"\n- Farmer category: {ctx.get('category', 'small')}"
            )

        if state.get("tool_outputs"):
            context_parts.append(
                f"\nData from tools:\n{json.dumps(state['tool_outputs'], indent=2)}"
            )

        if state.get("rag_results"):
            context_parts.append(
                f"\nKnowledge base results:\n{state['rag_results'].get('answer', '')}"
            )

        full_context = "\n".join(context_parts)

        response = await llm.ainvoke([
            SystemMessage(content=system_prompt),
            HumanMessage(content=full_context),
        ])

        return {
            **state,
            "specialist_response": response.content,
            "current_agent": agent_name,
            "messages": [AIMessage(content=f"[{agent_name}] {response.content[:100]}...")]
        }

    specialist_node.__name__ = agent_name
    return specialist_node


# ── Routing Logic ─────────────────────────────────────────────────────────────
def route_to_specialist(state: FarmState) -> str:
    """
    Determines where to go after supervisor runs.
    This is the conditional edge function.
    """
    decision = state.get("routing_decision", "END")

    valid_agents = [
        "crop_advisor", "pest_detector", "irrigation_planner",
        "market_analyst", "scheme_navigator"
    ]

    if decision in valid_agents:
        return decision
    return END


# ── Build the Graph ───────────────────────────────────────────────────────────
def build_supervisor_graph():
    """
    Assemble the complete multi-agent graph.

    📖 NOTE: StateGraph is like building a flowchart in code.
    add_node = "add a box to the flowchart"
    add_edge = "draw an arrow from A to B"
    add_conditional_edges = "draw arrows with conditions (if X then go to A, else B)"
    set_entry_point = "where the flow starts"
    compile() = "lock the flowchart, make it runnable"
    """
    graph = StateGraph(FarmState)

    # ── Add nodes ─────────────────────────────────────────────────────────────
    graph.add_node("supervisor", supervisor_node)
    graph.add_node("crop_advisor", make_specialist_node("crop_advisor"))
    graph.add_node("pest_detector", make_specialist_node("pest_detector"))
    graph.add_node("irrigation_planner", make_specialist_node("irrigation_planner"))
    graph.add_node("market_analyst", make_specialist_node("market_analyst"))
    graph.add_node("scheme_navigator", make_specialist_node("scheme_navigator"))

    # ── Add edges ─────────────────────────────────────────────────────────────
    # Supervisor decides where to go next (conditional)
    graph.add_conditional_edges(
        "supervisor",
        route_to_specialist,
        {
            "crop_advisor": "crop_advisor",
            "pest_detector": "pest_detector",
            "irrigation_planner": "irrigation_planner",
            "market_analyst": "market_analyst",
            "scheme_navigator": "scheme_navigator",
            END: END,  # Supervisor says we're done
        }
    )

    # All specialists report BACK to supervisor
    # (Supervisor checks if query is fully answered or needs another agent)
    for specialist in ["crop_advisor", "pest_detector", "irrigation_planner",
                        "market_analyst", "scheme_navigator"]:
        graph.add_edge(specialist, "supervisor")

    # ── Entry point ───────────────────────────────────────────────────────────
    graph.set_entry_point("supervisor")

    # ── Memory (checkpointing) ────────────────────────────────────────────────
    # MemorySaver persists state between graph invocations.
    # This lets you continue a conversation across multiple messages.
    # In production, use PostgresSaver for persistence across restarts.
    memory = MemorySaver()

    return graph.compile(checkpointer=memory)


# ── Main Entry Point ──────────────────────────────────────────────────────────
async def run_agent(
    query: str,
    farmer_id: str = "demo-farmer",
    farmer_context: Optional[dict] = None,
    image_data: Optional[str] = None,
    thread_id: Optional[str] = None,
) -> dict:
    """
    Run the multi-agent system for a farmer query.

    Args:
        query: The farmer's question
        farmer_id: Farmer's unique ID (for memory)
        farmer_context: Farmer profile dict
        image_data: Base64 image for pest detection
        thread_id: Conversation thread ID (for multi-turn)

    Returns:
        dict with final_response, agent_used, and messages
    """
    graph = build_supervisor_graph()

    # Initial state
    initial_state = FarmState(
        farmer_id=farmer_id,
        query=query,
        messages=[HumanMessage(content=query)],
        image_data=image_data,
        farmer_context=farmer_context or {
            "name": "Farmer",
            "location": "India",
            "current_crops": "Not specified",
            "land_acres": 5,
            "irrigation_type": "flood",
            "category": "small",
        },
        current_agent="supervisor",
        tool_outputs={},
        rag_results={},
        specialist_response=None,
        final_response=None,
        routing_decision=None,
        iteration_count=0,
    )

    # Config: thread_id enables conversation memory
    config = {"configurable": {"thread_id": thread_id or farmer_id}}

    # Run the graph
    result = await graph.ainvoke(initial_state, config=config)

    return {
        "final_response": result.get("final_response") or result.get("specialist_response", "I couldn't process your query. Please try again."),
        "agent_used": result.get("current_agent", "unknown"),
        "farmer_id": farmer_id,
        "query": query,
    }
