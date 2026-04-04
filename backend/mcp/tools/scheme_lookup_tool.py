"""
scheme_lookup_tool.py — Government scheme eligibility checker.

📖 LEARNING NOTE — When to use MCP Tool vs. RAG:
    This is a nuanced design decision you'll face as an engineer.

    USE MCP TOOL when:
    - Data is structured (eligibility rules, fixed criteria)
    - You need real-time data (current prices, live weather)
    - Logic is computable (if land < 2 acres AND income < 1.5L → eligible)

    USE RAG when:
    - Data is unstructured (PDFs, policy documents, guidelines)
    - You need semantic search ("what schemes help organic farmers?")
    - Documents are too large to fit in prompt

    FarmAI uses BOTH:
    - This tool: structured eligibility check (fast, deterministic)
    - RAG pipeline: detailed scheme info, documents, application steps
"""

from datetime import datetime


# ── Government Scheme Database ───────────────────────────────────────────────
# This would normally come from a database or official API.
# We hardcode realistic data for the demo.

GOVERNMENT_SCHEMES = [
    {
        "id": "pm-kisan",
        "name": "PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)",
        "ministry": "Ministry of Agriculture & Farmers Welfare",
        "benefit": "₹6,000/year direct transfer (₹2,000 every 4 months)",
        "type": "Income Support",
        "eligibility": {
            "farmer_categories": ["small", "marginal", "all"],
            "land_max_acres": None,  # No upper limit since 2019
            "excluded": ["Government employees", "Income tax payers", "Professionals"],
            "documents": ["Aadhaar", "Land records (Khatauni)", "Bank account"],
        },
        "application": "https://pmkisan.gov.in or nearest CSC center",
        "active": True,
        "crops": "all",  # Not crop-specific
        "states": "all",
    },
    {
        "id": "pmfby",
        "name": "PMFBY (Pradhan Mantri Fasal Bima Yojana)",
        "ministry": "Ministry of Agriculture",
        "benefit": "Crop insurance — farmers pay 1.5-2% premium, govt pays rest",
        "type": "Insurance",
        "eligibility": {
            "farmer_categories": ["small", "marginal", "large"],
            "land_max_acres": None,
            "excluded": [],
            "documents": ["Land records", "Aadhaar", "Bank account", "Sowing certificate"],
        },
        "application": "Through bank branches or insurance companies before sowing",
        "active": True,
        "crops": ["wheat", "rice", "cotton", "groundnut", "soybean", "maize", "mustard"],
        "states": "all",
        "note": "Enrollment must be done within 2 weeks of sowing",
    },
    {
        "id": "kcc",
        "name": "Kisan Credit Card (KCC)",
        "ministry": "Ministry of Finance / NABARD",
        "benefit": "Short-term crop loan at 4-7% interest (subsidized)",
        "type": "Credit / Loan",
        "eligibility": {
            "farmer_categories": ["small", "marginal", "large"],
            "land_max_acres": None,
            "excluded": [],
            "documents": ["Land records", "Aadhaar", "Photo", "Bank account"],
        },
        "application": "Nearest bank (SBI, cooperative bank, regional rural bank)",
        "active": True,
        "crops": "all",
        "states": "all",
        "credit_limit_formula": "Land area × crop × scale of finance",
    },
    {
        "id": "pkvy",
        "name": "PKVY (Paramparagat Krishi Vikas Yojana)",
        "ministry": "Ministry of Agriculture",
        "benefit": "₹50,000/ha over 3 years for organic farming conversion",
        "type": "Subsidy - Organic Farming",
        "eligibility": {
            "farmer_categories": ["small", "marginal"],
            "land_max_acres": 12,  # ~5 hectares
            "excluded": [],
            "documents": ["Land records", "Group formation (cluster of 20 farmers)", "Aadhaar"],
        },
        "application": "Through agriculture department or Farmer Producer Organizations",
        "active": True,
        "crops": "all",
        "states": "all",
        "note": "Must form a 20-farmer cluster. Not for individual applications.",
    },
    {
        "id": "smam",
        "name": "SMAM (Sub-Mission on Agricultural Mechanization)",
        "ministry": "Ministry of Agriculture",
        "benefit": "25-50% subsidy on farm machinery and equipment",
        "type": "Subsidy - Equipment",
        "eligibility": {
            "farmer_categories": ["small", "marginal"],
            "land_max_acres": 20,
            "excluded": ["Large farmers may get reduced subsidy"],
            "documents": ["Land records", "Aadhaar", "Quotation from dealer"],
        },
        "application": "State agriculture department portals",
        "active": True,
        "crops": "all",
        "states": "all",
        "machinery": ["Tractors", "Power tillers", "Seed drills", "Sprayers", "Harvesters"],
    },
    {
        "id": "drip-subsidy",
        "name": "PMKSY-PDMC (Micro Irrigation Subsidy)",
        "ministry": "Ministry of Agriculture - PMKSY",
        "benefit": "55% subsidy for small/marginal, 45% for others on drip/sprinkler irrigation",
        "type": "Subsidy - Irrigation",
        "eligibility": {
            "farmer_categories": ["small", "marginal", "large"],
            "land_max_acres": None,
            "excluded": [],
            "documents": ["Land records", "Aadhaar", "Water source certificate"],
        },
        "application": "State horticulture/agriculture departments",
        "active": True,
        "crops": ["cotton", "sugarcane", "banana", "vegetables", "orchards"],
        "states": "all",
    },
]


async def find_eligible_schemes(
    state: str,
    crop: str,
    farmer_category: str
) -> list:
    """
    Find government schemes a farmer is likely eligible for.

    Args:
        state: Farmer's state (telangana, maharashtra, etc.)
        crop: Primary crop being grown
        farmer_category: "small" (< 2 acres), "marginal" (2-5 acres), or "large" (> 5 acres)

    Returns:
        List of eligible schemes with benefits, eligibility, and application info
    """
    eligible = []

    for scheme in GOVERNMENT_SCHEMES:
        if not scheme["active"]:
            continue

        # Check farmer category
        cats = scheme["eligibility"]["farmer_categories"]
        if "all" not in cats and farmer_category.lower() not in cats:
            continue

        # Check crop eligibility
        scheme_crops = scheme.get("crops", "all")
        if scheme_crops != "all":
            if crop.lower() not in [c.lower() for c in scheme_crops]:
                continue

        # Check state
        scheme_states = scheme.get("states", "all")
        if scheme_states != "all" and state.lower() not in scheme_states:
            continue

        eligible.append({
            "scheme_id": scheme["id"],
            "name": scheme["name"],
            "type": scheme["type"],
            "benefit": scheme["benefit"],
            "key_documents": scheme["eligibility"]["documents"],
            "how_to_apply": scheme["application"],
            "notes": scheme.get("note", ""),
            "priority": _calculate_priority(scheme, farmer_category),
        })

    # Sort by priority (most impactful first)
    eligible.sort(key=lambda x: x["priority"], reverse=True)

    return {
        "farmer_profile": {
            "state": state,
            "crop": crop,
            "category": farmer_category,
        },
        "total_eligible_schemes": len(eligible),
        "schemes": eligible,
        "next_steps": (
            "Start with PM-KISAN registration if not done — it's the easiest "
            "and gives guaranteed ₹6,000/year. Then apply for crop insurance (PMFBY) "
            "before your next sowing season."
        ),
        "data_source": "Central government scheme database (as of FY 2024-25)"
    }


def _calculate_priority(scheme: dict, farmer_category: str) -> int:
    """
    Score scheme by impact for the farmer.
    Higher = more important to apply for first.
    """
    priority_map = {
        "Income Support": 100,   # PM-KISAN — everyone should have this
        "Insurance": 90,          # PMFBY — protects against crop failure
        "Credit / Loan": 80,      # KCC — cheap credit
        "Subsidy - Irrigation": 70,
        "Subsidy - Equipment": 60,
        "Subsidy - Organic Farming": 50,
    }
    base = priority_map.get(scheme.get("type", ""), 40)

    # Small/marginal farmers get higher subsidies — boost relevance
    if farmer_category in ["small", "marginal"]:
        base += 10

    return base
