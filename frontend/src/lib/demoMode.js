export function getDemoResponse(message) {
  const msg = message.toLowerCase()

  if (msg.includes('crop') || msg.includes('plant') || msg.includes('rabi') || msg.includes('kharif')) {
    return {
      agent: 'crop_advisor',
      text: '🌾 Based on your location in Telangana and the current Rabi season:\n\n**Top 3 recommendations:**\n\n1. **Wheat** (Variety: HI-8498)\n   - Sow: November 15 - December 15\n   - Expected yield: 35-40 q/ha\n\n2. **Chickpea (Chana)** (Variety: JG-11)\n   - Lower water need — good for drip system\n   - MSP: ₹5,440/quintal\n\n3. **Safflower** (drought tolerant)\n\n[Source: crop_guides knowledge base + MCP weather tool]',
    }
  }

  if (msg.includes('pest') || msg.includes('disease') || msg.includes('spots') || msg.includes('yellow') || msg.includes('blight')) {
    return {
      agent: 'pest_detector',
      text: '🔬 **Diagnosis: Early Blight (Alternaria solani)** — Confidence: HIGH\n\n**Immediate Action:**\nSpray Mancozeb 75% WP @ 2.5g/liter\n\n**Follow-up:** Spray every 10-14 days, avoid overhead irrigation.\n\n[Source: pest_library knowledge base]',
    }
  }

  if (msg.includes('price') || msg.includes('sell') || msg.includes('mandi') || msg.includes('market')) {
    return {
      agent: 'market_analyst',
      text: '📈 **Cotton Market Update — Telangana**\n\nModal price: ₹7,200/quintal\nMSP: ₹7,020/quintal (**above MSP** ✅)\n\n**Recommendation:** SELL NOW — prices trending up.\n\n[Source: MCP mandi_prices tool]',
    }
  }

  if (msg.includes('irrigat') || msg.includes('water')) {
    return {
      agent: 'irrigation_planner',
      text: '💧 **Irrigation Advisory**\n\nToday & Tomorrow: Skip (soil moisture adequate)\nWednesday: Rain expected — skip\nThursday-Friday: Resume drip — 40 min/day\n\n[Source: MCP weather_forecast + soil_analysis tools]',
    }
  }

  if (msg.includes('scheme') || msg.includes('subsid') || msg.includes('pm-kisan') || msg.includes('government')) {
    return {
      agent: 'scheme_navigator',
      text: '🏛️ **You are eligible for:**\n\n1. **PM-KISAN** ✅ — ₹6,000/year\n2. **PMFBY Crop Insurance** ✅ — 1.5% premium\n3. **Kisan Credit Card** ✅ — 4% interest loan\n\nStart with PM-KISAN registration at pmkisan.gov.in\n\n[Source: MCP government_schemes tool]',
    }
  }

  return {
    agent: 'supervisor',
    text: 'I understand your query. As FarmAI supervisor, I route to specialists:\n\n🌾 Crop Advisor — planting & fertilizer\n🔬 Pest Detector — disease diagnosis\n📈 Market Analyst — prices & selling\n💧 Irrigation Planner — water scheduling\n🏛️ Scheme Navigator — government benefits\n\nTry asking about one of these topics!',
  }
}
