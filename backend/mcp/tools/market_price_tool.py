"""
market_price_tool.py — Mandi/market price tool for MCP server.

📖 LEARNING NOTE — Why this as an MCP tool vs. hardcoded in the agent?
    Great question! You COULD just call this API directly inside an agent.
    But with MCP:
    1. Any agent can reuse this tool (crop advisor, market analyst, etc.)
    2. Claude Desktop users can also call it — without your custom app
    3. You can update the tool logic without touching agent code
    4. The tool is discoverable: the AI can READ the docstring and understand
       when/how to use it. The docstring IS the tool's instruction.

    This is the "Unix philosophy" for AI: small, focused tools that compose.
"""

import httpx
import random
from datetime import datetime, timedelta
from config import settings


# ── Real mandi price data sources ───────────────────────────────────────────
# India has the AgMarkNet portal (agmarknet.gov.in) for mandi prices.
# Many states also expose APIs. We mock it here for the demo.

# Realistic MSP (Minimum Support Price) and market ranges for major crops
CROP_PRICE_DATA = {
    "wheat": {
        "msp_per_quintal": 2275,
        "market_range": (2100, 2800),
        "unit": "quintal",
        "seasonal_peak": [3, 4],   # March-April (post-harvest Rabi)
        "seasonal_low": [10, 11],  # Oct-Nov (pre-harvest season)
    },
    "rice": {
        "msp_per_quintal": 2300,
        "market_range": (2000, 3200),
        "unit": "quintal",
        "seasonal_peak": [1, 2],   # Jan-Feb
        "seasonal_low": [10, 11],  # Kharif harvest glut
    },
    "cotton": {
        "msp_per_quintal": 7020,
        "market_range": (6500, 9000),
        "unit": "quintal",
        "seasonal_peak": [4, 5],
        "seasonal_low": [11, 12],
    },
    "tomato": {
        "msp_per_quintal": None,   # No MSP for vegetables
        "market_range": (200, 4000),  # Very volatile!
        "unit": "quintal",
        "seasonal_peak": [11, 12],
        "seasonal_low": [7, 8],
    },
    "soybean": {
        "msp_per_quintal": 4892,
        "market_range": (4500, 6500),
        "unit": "quintal",
        "seasonal_peak": [12, 1],
        "seasonal_low": [10, 11],
    },
    "maize": {
        "msp_per_quintal": 2090,
        "market_range": (1800, 2800),
        "unit": "quintal",
        "seasonal_peak": [2, 3],
        "seasonal_low": [10, 11],
    },
}

# Major mandi locations by state
STATE_MANDIS = {
    "telangana": ["Hyderabad (Bowenpally)", "Warangal", "Karimnagar", "Nizamabad"],
    "maharashtra": ["Pune (APMC)", "Nashik", "Nagpur", "Aurangabad"],
    "punjab": ["Amritsar", "Ludhiana", "Khanna", "Moga"],
    "karnataka": ["Bangalore (APMC)", "Hubli", "Mysore", "Belgaum"],
    "uttar_pradesh": ["Lucknow", "Agra", "Kanpur", "Varanasi"],
    "default": ["Local Mandi", "District APMC"],
}


async def get_mandi_prices(crop: str, state: str) -> dict:
    """
    Fetch latest market prices for a crop from state mandis.

    Returns current prices, MSP comparison, trend analysis,
    and a selling recommendation — exactly what a farmer needs
    to decide when and where to sell.

    Args:
        crop: Crop name (wheat, rice, cotton, tomato, soybean, maize)
        state: Indian state name (telangana, maharashtra, punjab, etc.)

    Returns:
        dict with prices, trends, MSP comparison, and recommendation
    """
    crop_lower = crop.lower().strip()
    state_lower = state.lower().strip().replace(" ", "_")

    # Try real API first (if configured)
    if settings.agmarknet_api_key:
        try:
            return await _fetch_real_prices(crop_lower, state_lower)
        except Exception:
            pass  # Fall through to mock

    # Return mock data (realistic and educational)
    return _generate_mock_prices(crop_lower, state_lower)


def _generate_mock_prices(crop: str, state: str) -> dict:
    """
    Generate realistic mock mandi prices.
    Uses seasonal logic — prices actually vary by harvest timing in India.
    """
    crop_data = CROP_PRICE_DATA.get(crop, {
        "msp_per_quintal": None,
        "market_range": (1000, 5000),
        "unit": "quintal",
        "seasonal_peak": [12, 1],
        "seasonal_low": [10, 11],
    })

    mandis = STATE_MANDIS.get(state, STATE_MANDIS["default"])
    current_month = datetime.now().month

    # Simulate seasonal price movement
    is_peak = current_month in crop_data["seasonal_peak"]
    is_low = current_month in crop_data["seasonal_low"]

    price_min, price_max = crop_data["market_range"]
    if is_peak:
        current_price = int(price_min + (price_max - price_min) * 0.8)
    elif is_low:
        current_price = int(price_min + (price_max - price_min) * 0.2)
    else:
        current_price = int(price_min + (price_max - price_min) * 0.5)

    # Generate per-mandi data (slight variation)
    mandi_prices = []
    for mandi in mandis:
        variation = random.randint(-100, 150)
        mandi_prices.append({
            "mandi": mandi,
            "price_per_quintal": current_price + variation,
            "arrivals_quintals": random.randint(500, 5000),
            "date": datetime.now().strftime("%Y-%m-%d"),
        })

    # Sort — farmer should sell at highest price mandi
    mandi_prices.sort(key=lambda x: x["price_per_quintal"], reverse=True)
    best_mandi = mandi_prices[0]

    # Historical trend (last 30 days simulated)
    trend_data = []
    for i in range(30, 0, -1):
        date = datetime.now() - timedelta(days=i)
        trend_price = current_price + random.randint(-200, 200)
        trend_data.append({
            "date": date.strftime("%Y-%m-%d"),
            "price": trend_price,
        })

    msp = crop_data["msp_per_quintal"]
    above_msp = (current_price > msp) if msp else None
    msp_premium = (current_price - msp) if msp else None

    return {
        "crop": crop,
        "state": state,
        "current_market_price": current_price,
        "unit": crop_data["unit"],
        "msp": msp,
        "above_msp": above_msp,
        "msp_premium_rs": msp_premium,
        "mandi_prices": mandi_prices,
        "best_mandi": best_mandi["mandi"],
        "best_price": best_mandi["price_per_quintal"],
        "30_day_trend": trend_data,
        "price_trend": "Rising" if is_peak else ("Falling" if is_low else "Stable"),
        # ── The key insight for a farmer ──────────────────────────────
        "recommendation": _generate_price_recommendation(
            crop, current_price, msp, is_peak, is_low, best_mandi
        ),
        "data_source": "Mock (AgMarkNet format — set AGMARKNET_API_KEY for real data)"
    }


def _generate_price_recommendation(
    crop: str, price: int, msp, is_peak: bool, is_low: bool, best_mandi: dict
) -> str:
    """
    Generate a human-readable selling recommendation.
    This is where domain knowledge + data = real farmer value.
    """
    rec = []

    if is_peak:
        rec.append(f"✅ SELL NOW — Prices are near seasonal peak (₹{price}/quintal).")
    elif is_low:
        rec.append(f"⚠️ HOLD if possible — Prices are seasonally low. Consider storing for 4-6 weeks.")
    else:
        rec.append(f"📊 NEUTRAL — Prices are moderate. Watch for 2-3 week trend before deciding.")

    if msp and price < msp:
        rec.append(f"🚨 CRITICAL: Market price (₹{price}) is BELOW MSP (₹{msp}). "
                   f"Contact your state procurement agency for MSP purchase.")
    elif msp:
        rec.append(f"Market price is ₹{price - msp} above MSP — reasonable premium.")

    rec.append(f"Best mandi: {best_mandi['mandi']} at ₹{best_mandi['price_per_quintal']}/quintal.")

    return " ".join(rec)


async def _fetch_real_prices(crop: str, state: str) -> dict:
    """
    Placeholder for real AgMarkNet / data.gov.in API integration.
    The actual API requires registration and state-specific endpoints.
    """
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070",
            params={
                "api-key": settings.agmarknet_api_key,
                "format": "json",
                "filters[Commodity]": crop.capitalize(),
                "filters[State]": state.capitalize(),
                "limit": 10,
            }
        )
        # Parse and return in our standard format
        return resp.json()
