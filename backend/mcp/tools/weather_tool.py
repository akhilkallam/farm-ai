"""
weather_tool.py — Weather data tool for MCP server.

📖 LEARNING NOTE — MCP Tools are just async Python functions!
    The magic is in how they're REGISTERED with the MCP server (see server.py).
    The function itself is normal Python — it calls an external API,
    processes the response, and returns structured data.

    MCP handles:
    - Serializing the function signature into a JSON schema (so the AI knows
      what parameters to pass)
    - Routing the AI's tool call to this function
    - Sending the result back to the AI

    You write: normal Python async functions
    MCP gives you: any AI can call them automatically
"""

import httpx
from datetime import datetime
from config import settings


async def get_weather_forecast(location: str, days: int = 7) -> dict:
    """
    Fetches weather forecast for a farm location.

    In production: calls OpenWeatherMap API.
    In development (no API key): returns realistic mock data.

    Args:
        location: City/region name (e.g., "Hyderabad", "Vidarbha")
        days: Number of forecast days (1-7)

    Returns:
        dict with temperature, rainfall, humidity, wind, farming_advice
    """

    # ── If we have a real API key, use OpenWeatherMap ──────────────
    if settings.openweather_api_key:
        async with httpx.AsyncClient() as client:
            # First: Geocode location name → lat/lon
            geo_resp = await client.get(
                "http://api.openweathermap.org/geo/1.0/direct",
                params={
                    "q": location,
                    "limit": 1,
                    "appid": settings.openweather_api_key
                }
            )
            geo_data = geo_resp.json()
            if not geo_data:
                return {"error": f"Location '{location}' not found"}

            lat = geo_data[0]["lat"]
            lon = geo_data[0]["lon"]

            # Then: Get forecast
            forecast_resp = await client.get(
                "https://api.openweathermap.org/data/2.5/forecast",
                params={
                    "lat": lat,
                    "lon": lon,
                    "cnt": days * 8,  # 8 slots per day (3-hour intervals)
                    "appid": settings.openweather_api_key,
                    "units": "metric"
                }
            )
            data = forecast_resp.json()
            return _parse_openweather_response(data, location, days)

    # ── Mock data for development (no API key needed) ───────────────
    # This is great for learning — you can test the full agent flow
    # without spending money on API calls
    return _mock_weather(location, days)


def _mock_weather(location: str, days: int) -> dict:
    """Realistic mock weather data for Indian farming regions."""
    # Simulate seasonal data based on current month
    month = datetime.now().month

    # Rabi season (Oct-Mar): cool and dry
    # Kharif season (Jun-Sep): hot and wet
    is_kharif = 6 <= month <= 9

    daily_forecasts = []
    for day in range(days):
        daily_forecasts.append({
            "date": f"Day {day + 1}",
            "temp_max_c": 32 if is_kharif else 26,
            "temp_min_c": 24 if is_kharif else 14,
            "humidity_pct": 78 if is_kharif else 45,
            "rainfall_mm": 12.5 if (is_kharif and day % 2 == 0) else 0,
            "wind_kmh": 15,
            "conditions": "Partly cloudy with chance of rain" if is_kharif else "Clear and sunny",
        })

    total_rainfall = sum(d["rainfall_mm"] for d in daily_forecasts)

    return {
        "location": location,
        "forecast_days": days,
        "season": "Kharif (Monsoon)" if is_kharif else "Rabi (Winter)",
        "daily": daily_forecasts,
        "summary": {
            "avg_temp_c": 28 if is_kharif else 20,
            "total_rainfall_mm": total_rainfall,
            "avg_humidity_pct": 78 if is_kharif else 45,
        },
        # ── KEY: farming-specific interpretation ─────────────────────
        # This is what makes FarmAI different from a plain weather app.
        # We translate raw weather into actionable farming advice.
        "farming_advice": {
            "irrigation_needed": total_rainfall < 50,
            "spray_window": "Avoid spraying on rainy days. Best window: morning hours.",
            "harvest_risk": "High moisture risk" if total_rainfall > 100 else "Low risk",
            "sowing_condition": "Good" if not is_kharif else "Wait for soil moisture balance",
        },
        "data_source": "Mock (set OPENWEATHER_API_KEY for real data)"
    }


def _parse_openweather_response(data: dict, location: str, days: int) -> dict:
    """Parse real OpenWeatherMap API response into our standardized format."""
    daily_forecasts = []
    seen_dates = set()

    for item in data.get("list", []):
        date = item["dt_txt"].split(" ")[0]
        if date not in seen_dates and len(daily_forecasts) < days:
            seen_dates.add(date)
            daily_forecasts.append({
                "date": date,
                "temp_max_c": item["main"]["temp_max"],
                "temp_min_c": item["main"]["temp_min"],
                "humidity_pct": item["main"]["humidity"],
                "rainfall_mm": item.get("rain", {}).get("3h", 0) * 8,  # scale to daily
                "wind_kmh": item["wind"]["speed"] * 3.6,
                "conditions": item["weather"][0]["description"],
            })

    total_rainfall = sum(d["rainfall_mm"] for d in daily_forecasts)

    return {
        "location": location,
        "forecast_days": days,
        "daily": daily_forecasts,
        "summary": {
            "total_rainfall_mm": total_rainfall,
        },
        "farming_advice": {
            "irrigation_needed": total_rainfall < 50,
            "spray_window": "Avoid rainy days",
            "harvest_risk": "High" if total_rainfall > 100 else "Low",
        },
        "data_source": "OpenWeatherMap API"
    }
