"""
soil_tool.py — Soil analysis and NPK recommendations.

📖 LEARNING NOTE — MCP Tool Design Principle:
    A good MCP tool is NARROW and SPECIFIC. It does one thing well.
    Bad tool: get_farm_data(location) → returns weather + soil + prices
    Good tools: get_weather(location), get_soil(lat, lon), get_prices(crop, state)

    Why? Because the AI (Claude) reads your tool's docstring and decides
    which tool to call. If tools are too broad, the AI gets confused.
    Narrow tools = better AI decisions = better user experience.

    Also notice: every tool returns structured data (dicts), never raw text.
    The AI will reason over the structured data in its response.
"""

# ── Soil type database for major Indian farming regions ─────────────────────
# In production: integrate with ICAR soil map API or Soilgrids.org

SOIL_DATABASE = {
    # Format: (lat_min, lat_max, lon_min, lon_max): soil_profile
    "telangana": {
        "lat_range": (15.8, 19.9),
        "lon_range": (77.2, 81.3),
        "soil_type": "Red and Laterite",
        "texture": "Sandy loam to clay loam",
        "ph_range": (5.5, 6.5),
        "organic_carbon_pct": 0.4,
        "typical_npk": {
            "nitrogen_kg_ha": 150,   # Low nitrogen — needs supplementation
            "phosphorus_kg_ha": 20,
            "potassium_kg_ha": 120,
        },
        "deficiencies": ["Nitrogen", "Zinc", "Boron"],
        "suitable_crops": ["Cotton", "Sorghum", "Groundnut", "Maize", "Pulses"],
    },
    "punjab": {
        "lat_range": (29.5, 32.5),
        "lon_range": (73.8, 76.9),
        "soil_type": "Alluvial",
        "texture": "Loam to silty loam",
        "ph_range": (7.5, 8.5),
        "organic_carbon_pct": 0.6,
        "typical_npk": {
            "nitrogen_kg_ha": 180,
            "phosphorus_kg_ha": 35,
            "potassium_kg_ha": 200,
        },
        "deficiencies": ["Zinc", "Iron"],
        "suitable_crops": ["Wheat", "Rice", "Maize", "Sugarcane"],
    },
    "vidarbha": {
        "lat_range": (19.5, 22.0),
        "lon_range": (76.5, 81.0),
        "soil_type": "Black Cotton (Vertisols)",
        "texture": "Heavy clay",
        "ph_range": (7.0, 8.0),
        "organic_carbon_pct": 0.7,
        "typical_npk": {
            "nitrogen_kg_ha": 200,
            "phosphorus_kg_ha": 30,
            "potassium_kg_ha": 400,  # High potassium — characteristic of black soil
        },
        "deficiencies": ["Phosphorus", "Sulfur", "Boron"],
        "suitable_crops": ["Cotton", "Soybean", "Wheat", "Sorghum", "Orange"],
    },
    "default": {
        "soil_type": "Mixed alluvial",
        "texture": "Loam",
        "ph_range": (6.0, 7.5),
        "organic_carbon_pct": 0.5,
        "typical_npk": {
            "nitrogen_kg_ha": 160,
            "phosphorus_kg_ha": 25,
            "potassium_kg_ha": 180,
        },
        "deficiencies": ["Zinc"],
        "suitable_crops": ["Wheat", "Rice", "Vegetables"],
    }
}


async def get_soil_recommendations(lat: float, lon: float) -> dict:
    """
    Get soil type, pH, NPK levels, and crop recommendations for given GPS coordinates.

    This is especially valuable in India where soil varies dramatically
    across even small distances (e.g., black soil in Vidarbha vs. red soil
    in Telangana 200km south).

    Args:
        lat: Latitude (decimal degrees, e.g., 17.3850)
        lon: Longitude (decimal degrees, e.g., 78.4867)

    Returns:
        dict with soil profile, NPK analysis, deficiencies, and fertilizer recommendations
    """
    soil_profile = _get_soil_for_location(lat, lon)

    # Build NPK fertilizer recommendations
    npk = soil_profile["typical_npk"]
    fertilizer_recs = _calculate_fertilizer_recommendations(npk, soil_profile)

    return {
        "coordinates": {"lat": lat, "lon": lon},
        "soil_type": soil_profile["soil_type"],
        "texture": soil_profile.get("texture", "N/A"),
        "ph_range": {
            "min": soil_profile["ph_range"][0],
            "max": soil_profile["ph_range"][1],
            "interpretation": _interpret_ph(soil_profile["ph_range"])
        },
        "organic_carbon": {
            "value_pct": soil_profile["organic_carbon_pct"],
            "status": "Low" if soil_profile["organic_carbon_pct"] < 0.5 else "Medium",
            "recommendation": (
                "Add FYM (Farmyard Manure) 5-10 tonnes/ha to improve organic carbon"
                if soil_profile["organic_carbon_pct"] < 0.5
                else "Organic carbon is adequate. Maintain with crop residue incorporation."
            )
        },
        "npk_status": npk,
        "nutrient_deficiencies": soil_profile.get("deficiencies", []),
        "fertilizer_recommendations": fertilizer_recs,
        "suitable_crops": soil_profile.get("suitable_crops", []),
        # ── Actionable summary ───────────────────────────────────────
        "farmer_summary": _generate_soil_summary(soil_profile, npk),
        "data_source": "Regional soil database (integrate ICAR API for plot-level data)"
    }


def _get_soil_for_location(lat: float, lon: float) -> dict:
    """Match coordinates to known soil region."""
    for region, data in SOIL_DATABASE.items():
        if region == "default":
            continue
        if (data.get("lat_range", [0, 0])[0] <= lat <= data.get("lat_range", [0, 0])[1] and
                data.get("lon_range", [0, 0])[0] <= lon <= data.get("lon_range", [0, 0])[1]):
            return data
    return SOIL_DATABASE["default"]


def _interpret_ph(ph_range: tuple) -> str:
    avg = sum(ph_range) / 2
    if avg < 6.0:
        return "Acidic — may need lime application"
    elif avg > 7.5:
        return "Alkaline — may need gypsum or sulfur"
    else:
        return "Neutral — ideal for most crops"


def _calculate_fertilizer_recommendations(npk: dict, profile: dict) -> list:
    """Convert NPK soil data into specific fertilizer product recommendations."""
    recs = []

    # Nitrogen
    n = npk["nitrogen_kg_ha"]
    if n < 150:
        recs.append({
            "nutrient": "Nitrogen (N)",
            "status": "Low",
            "product": "Urea (46-0-0)",
            "dose_kg_ha": round((150 - n) / 0.46),
            "application": "Split in 2: 50% at sowing + 50% at 30 days"
        })
    else:
        recs.append({"nutrient": "Nitrogen", "status": "Adequate", "product": None})

    # Phosphorus
    p = npk["phosphorus_kg_ha"]
    if p < 30:
        recs.append({
            "nutrient": "Phosphorus (P)",
            "status": "Low",
            "product": "DAP (18-46-0)",
            "dose_kg_ha": round((30 - p) / 0.46),
            "application": "Full dose at sowing time"
        })

    # Potassium
    k = npk["potassium_kg_ha"]
    if k < 150:
        recs.append({
            "nutrient": "Potassium (K)",
            "status": "Low",
            "product": "MOP (Muriate of Potash, 0-0-60)",
            "dose_kg_ha": round((150 - k) / 0.60),
            "application": "Full dose at sowing time"
        })

    # Micronutrient deficiencies
    for deficiency in profile.get("deficiencies", []):
        if deficiency == "Zinc":
            recs.append({
                "nutrient": "Zinc (Zn)",
                "status": "Deficient",
                "product": "Zinc Sulfate (21%)",
                "dose_kg_ha": 25,
                "application": "Soil application before sowing OR foliar @ 0.5% solution"
            })

    return recs


def _generate_soil_summary(profile: dict, npk: dict) -> str:
    """Plain language summary a farmer can act on immediately."""
    return (
        f"Your land has {profile['soil_type']} soil — "
        f"pH {profile['ph_range'][0]}-{profile['ph_range'][1]} ({_interpret_ph(profile['ph_range'])}). "
        f"It is well-suited for: {', '.join(profile.get('suitable_crops', [])[:3])}. "
        f"Key deficiencies to address: {', '.join(profile.get('deficiencies', ['None']))}."
    )
