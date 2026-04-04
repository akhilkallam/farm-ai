/**
 * FarmAI — Main Application
 * A single-file React app demonstrating the farmer chat interface.
 *
 * 📖 NOTE: In the real Next.js app, this would be split into:
 *   - app/page.tsx (this dashboard)
 *   - app/chat/page.tsx (chat UI)
 *   - app/pest/page.tsx (pest detection with image upload)
 *   - components/WeatherWidget.tsx
 *   - components/MarketPrices.tsx
 *
 * For the demo, we've combined everything into one file
 * that you can run directly or as a React artifact.
 */

import { useState, useRef, useEffect } from "react";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

// ── Agent badge colors ─────────────────────────────────────────────────────
const AGENT_COLORS = {
  crop_advisor: "bg-green-100 text-green-800",
  pest_detector: "bg-red-100 text-red-800",
  market_analyst: "bg-blue-100 text-blue-800",
  irrigation_planner: "bg-cyan-100 text-cyan-800",
  scheme_navigator: "bg-purple-100 text-purple-800",
  supervisor: "bg-gray-100 text-gray-800",
};

const AGENT_ICONS = {
  crop_advisor: "🌾",
  pest_detector: "🔬",
  market_analyst: "📈",
  irrigation_planner: "💧",
  scheme_navigator: "🏛️",
  supervisor: "🧠",
};

// ── Sample quick-ask buttons ───────────────────────────────────────────────
const QUICK_ASKS = [
  { text: "Which crop for Rabi season?", icon: "🌾" },
  { text: "My tomato leaves have brown spots", icon: "🍅" },
  { text: "Current wheat price in Telangana?", icon: "💰" },
  { text: "Should I irrigate today?", icon: "💧" },
  { text: "Am I eligible for PM-KISAN?", icon: "🏛️" },
  { text: "Best time to sell my cotton?", icon: "📊" },
];

// ── Chat Message Component ─────────────────────────────────────────────────
function Message({ msg }) {
  const isUser = msg.role === "user";

  return (
    <div className={`flex ${isUser ? "justify-end" : "justify-start"} mb-4`}>
      {!isUser && (
        <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white text-sm mr-2 flex-shrink-0 mt-1">
          🌱
        </div>
      )}
      <div className={`max-w-2xl ${isUser ? "items-end" : "items-start"} flex flex-col`}>
        <div
          className={`px-4 py-3 rounded-2xl ${
            isUser
              ? "bg-green-600 text-white rounded-tr-sm"
              : "bg-white text-gray-800 rounded-tl-sm shadow-sm border border-gray-100"
          }`}
        >
          <p className="text-sm leading-relaxed whitespace-pre-wrap">{msg.content}</p>
        </div>
        {msg.agent && (
          <div className="flex items-center gap-1 mt-1 ml-1">
            <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${AGENT_COLORS[msg.agent] || "bg-gray-100 text-gray-600"}`}>
              {AGENT_ICONS[msg.agent]} {msg.agent.replace("_", " ")}
            </span>
          </div>
        )}
        <span className="text-xs text-gray-400 mt-1 px-1">
          {new Date(msg.timestamp).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}
        </span>
      </div>
      {isUser && (
        <div className="w-8 h-8 rounded-full bg-green-700 flex items-center justify-center text-white text-sm ml-2 flex-shrink-0 mt-1">
          👨‍🌾
        </div>
      )}
    </div>
  );
}

// ── Loading indicator ──────────────────────────────────────────────────────
function ThinkingBubble() {
  const [dots, setDots] = useState(".");
  useEffect(() => {
    const id = setInterval(() => setDots(d => d.length >= 3 ? "." : d + "."), 500);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="flex justify-start mb-4">
      <div className="w-8 h-8 rounded-full bg-green-500 flex items-center justify-center text-white text-sm mr-2 flex-shrink-0">
        🌱
      </div>
      <div className="bg-white border border-gray-100 shadow-sm px-4 py-3 rounded-2xl rounded-tl-sm">
        <div className="flex items-center gap-2">
          <div className="flex gap-1">
            {[0, 1, 2].map(i => (
              <div
                key={i}
                className="w-2 h-2 bg-green-400 rounded-full animate-bounce"
                style={{ animationDelay: `${i * 0.15}s` }}
              />
            ))}
          </div>
          <span className="text-xs text-gray-500">Agents working{dots}</span>
        </div>
      </div>
    </div>
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────
function StatCard({ icon, label, value, sub }) {
  return (
    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
      <div className="flex items-center gap-3">
        <div className="text-2xl">{icon}</div>
        <div>
          <div className="text-xs text-gray-500">{label}</div>
          <div className="text-lg font-bold text-gray-800">{value}</div>
          {sub && <div className="text-xs text-green-600">{sub}</div>}
        </div>
      </div>
    </div>
  );
}

// ── Main App ───────────────────────────────────────────────────────────────
export default function FarmAIApp() {
  const [messages, setMessages] = useState([
    {
      id: 1,
      role: "assistant",
      content: "Namaste! 🙏 I'm FarmAI — your agricultural advisor powered by AI.\n\nI can help you with:\n• Crop planning and variety selection\n• Pest and disease diagnosis\n• Market prices and selling timing\n• Irrigation scheduling\n• Government scheme eligibility\n\nWhat would you like to know today?",
      agent: "supervisor",
      timestamp: new Date().toISOString(),
    }
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [farmerId] = useState("demo-farmer");
  const [activeTab, setActiveTab] = useState("chat");
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loading]);

  const sendMessage = async (text) => {
    const message = text || input.trim();
    if (!message) return;

    const userMsg = {
      id: Date.now(),
      role: "user",
      content: message,
      timestamp: new Date().toISOString(),
    };

    setMessages(prev => [...prev, userMsg]);
    setInput("");
    setLoading(true);

    try {
      const resp = await fetch(`${API_URL}/api/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          farmer_id: farmerId,
          message: message,
          thread_id: farmerId,
        }),
      });

      if (!resp.ok) throw new Error(`API error: ${resp.status}`);

      const data = await resp.json();

      setMessages(prev => [...prev, {
        id: Date.now() + 1,
        role: "assistant",
        content: data.response,
        agent: data.agent_used,
        timestamp: new Date().toISOString(),
      }]);
    } catch (err) {
      // Demo mode: simulate response when API not running
      const demoResponse = getDemoResponse(message);
      setMessages(prev => [...prev, {
        id: Date.now() + 1,
        role: "assistant",
        content: demoResponse.text,
        agent: demoResponse.agent,
        timestamp: new Date().toISOString(),
      }]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex flex-col">
      {/* Header */}
      <header className="bg-green-700 text-white px-4 py-3 shadow-md">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="text-2xl">🌱</div>
            <div>
              <h1 className="font-bold text-lg leading-tight">FarmAI</h1>
              <p className="text-green-200 text-xs">Powered by Claude + MCP + RAG + Multi-Agent</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-300 rounded-full animate-pulse"></div>
            <span className="text-xs text-green-200">All agents active</span>
          </div>
        </div>
      </header>

      {/* Tab Navigation */}
      <div className="bg-white border-b border-gray-200 px-4">
        <div className="max-w-4xl mx-auto flex gap-4">
          {["chat", "dashboard"].map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-3 px-2 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab
                  ? "border-green-600 text-green-700"
                  : "border-transparent text-gray-500 hover:text-gray-700"
              }`}
            >
              {tab === "chat" ? "💬 Chat" : "📊 Dashboard"}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 max-w-4xl mx-auto w-full px-4 py-4 flex flex-col">

        {activeTab === "dashboard" && (
          <div className="space-y-4">
            <h2 className="text-lg font-bold text-gray-700">Farm Overview</h2>
            <div className="grid grid-cols-2 gap-3">
              <StatCard icon="🌾" label="Current Crops" value="Cotton, Tomato" sub="Kharif season" />
              <StatCard icon="📍" label="Location" value="Warangal" sub="Telangana" />
              <StatCard icon="🏞️" label="Land" value="5.5 acres" sub="Small farmer" />
              <StatCard icon="💧" label="Irrigation" value="Drip system" sub="Installed" />
            </div>

            <h2 className="text-lg font-bold text-gray-700 mt-6">Agent System Status</h2>
            <div className="space-y-2">
              {Object.entries(AGENT_ICONS).map(([agent, icon]) => (
                agent !== "supervisor" && (
                  <div key={agent} className="bg-white rounded-xl p-3 shadow-sm border border-gray-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span>{icon}</span>
                      <span className="text-sm font-medium text-gray-700 capitalize">{agent.replace("_", " ")}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                      <span className="text-xs text-green-600">Ready</span>
                    </div>
                  </div>
                )
              ))}
            </div>

            <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
              <h3 className="font-bold text-gray-700 mb-2">🔌 MCP Tools Active</h3>
              <div className="space-y-2">
                {["🌤 weather_forecast(location, days)", "💰 mandi_prices(crop, state)", "🌍 soil_analysis(lat, lon)", "🏛 government_schemes(state, crop, category)"].map(tool => (
                  <div key={tool} className="text-xs text-gray-600 font-mono bg-gray-50 px-2 py-1 rounded">{tool}</div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === "chat" && (
          <>
            {/* Messages */}
            <div className="flex-1 overflow-y-auto py-2 space-y-1 min-h-0" style={{ maxHeight: "calc(100vh - 280px)" }}>
              {messages.map(msg => (
                <Message key={msg.id} msg={msg} />
              ))}
              {loading && <ThinkingBubble />}
              <div ref={messagesEndRef} />
            </div>

            {/* Quick Ask Buttons */}
            {messages.length <= 2 && (
              <div className="py-2">
                <p className="text-xs text-gray-500 mb-2 text-center">Try asking:</p>
                <div className="flex flex-wrap gap-2 justify-center">
                  {QUICK_ASKS.map((q, i) => (
                    <button
                      key={i}
                      onClick={() => sendMessage(q.text)}
                      className="text-xs bg-white border border-green-200 text-green-700 rounded-full px-3 py-1.5 hover:bg-green-50 transition-colors shadow-sm"
                    >
                      {q.icon} {q.text}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Input */}
            <div className="py-3">
              <div className="flex gap-2 bg-white rounded-2xl shadow-sm border border-gray-200 p-2">
                <textarea
                  value={input}
                  onChange={e => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Ask about crops, pests, prices, or schemes..."
                  className="flex-1 resize-none border-none outline-none text-sm text-gray-700 px-2 pt-1"
                  rows={1}
                  style={{ minHeight: "36px", maxHeight: "120px" }}
                />
                <button
                  onClick={() => sendMessage()}
                  disabled={loading || !input.trim()}
                  className="bg-green-600 text-white rounded-xl px-4 py-2 text-sm font-medium disabled:opacity-40 hover:bg-green-700 transition-colors flex-shrink-0"
                >
                  {loading ? "..." : "Send"}
                </button>
              </div>
              <p className="text-xs text-gray-400 text-center mt-1">
                Multi-agent AI • MCP tools • RAG knowledge base
              </p>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

// ── Demo mode responses (when API not running) ────────────────────────────
function getDemoResponse(message) {
  const msg = message.toLowerCase();

  if (msg.includes("crop") || msg.includes("plant") || msg.includes("rabi") || msg.includes("kharif")) {
    return {
      agent: "crop_advisor",
      text: "🌾 Based on your location in Telangana and the current Rabi season:\n\n**Top 3 recommendations for your 5.5 acre farm:**\n\n1. **Wheat** (Variety: HI-8498 'Malav Shakti')\n   - Sow: November 15 - December 15\n   - Expected yield: 35-40 q/ha\n   - Fertilizer: 120-60-40 kg N-P-K/ha\n\n2. **Chickpea (Chana)** (Variety: JG-11)\n   - Lower water need — good for drip system\n   - MSP: ₹5,440/quintal\n\n3. **Safflower** (if water is limited)\n   - Very drought tolerant\n   - Good market demand in Telangana\n\n🌡️ Weather check: Forecast shows cool temperatures (14-22°C) — ideal for Rabi sowing.\n\n[Data from: crop_guides knowledge base + MCP weather tool]"
    };
  }

  if (msg.includes("pest") || msg.includes("disease") || msg.includes("spots") || msg.includes("yellow") || msg.includes("blight")) {
    return {
      agent: "pest_detector",
      text: "🔬 **Diagnosis: Early Blight (Alternaria solani)** — Confidence: HIGH\n\nSymptoms matching your description:\n✓ Brown spots with yellow halo\n✓ Lower leaves affected first\n✓ Target ring/concentric pattern\n\n**Immediate Action (Today):**\nSpray Mancozeb 75% WP @ 2.5g/liter — cover all leaf surfaces\n\n**If severe (>30% leaves affected):**\nSwitch to Azoxystrobin 23% SC @ 1ml/liter (systemic, better efficacy)\n\n**Follow-up:**\n- Spray every 10-14 days\n- Avoid overhead irrigation\n- Remove and destroy heavily infected leaves\n\n**Cost:** Mancozeb ~₹120/kg, need ~200g for 5 acres = ₹24/spray\n\n[Source: pest_library knowledge base — Early Blight protocol]"
    };
  }

  if (msg.includes("price") || msg.includes("sell") || msg.includes("mandi") || msg.includes("market")) {
    return {
      agent: "market_analyst",
      text: "📈 **Cotton Market Update — Telangana**\n\n**Current Prices (Warangal Mandi):**\n• Modal price: ₹7,200/quintal\n• Range: ₹6,900 - ₹7,450/quintal\n• MSP: ₹7,020/quintal\n• **Premium above MSP: ₹180/quintal** ✅\n\n**Best Mandis Right Now:**\n1. Hyderabad (Bowenpally) — ₹7,380/q\n2. Warangal — ₹7,200/q\n3. Karimnagar — ₹7,150/q\n\n**30-Day Trend:** 📈 Rising (+₹340 over last month)\n\n**Recommendation:**\n✅ **SELL NOW** — Prices are above MSP and trending up. However, prices typically peak in Feb-March, so if you can hold 4-6 weeks and have good storage, you may get ₹7,500-7,800.\n\n[Data from: MCP mandi_prices tool]"
    };
  }

  if (msg.includes("irrigat") || msg.includes("water")) {
    return {
      agent: "irrigation_planner",
      text: "💧 **Irrigation Advisory for Today**\n\nBased on weather forecast and your drip system:\n\n**This week's rainfall forecast:** 8mm (light rain expected Wednesday)\n**Soil type:** Red soil — moderate water holding capacity\n**Current crop stage:** Cotton — boll development\n\n**Schedule:**\n• Today & Tomorrow: Skip irrigation (soil moisture adequate)\n• Wednesday: Rain expected — skip\n• Thursday-Friday: Resume drip — 40 minutes/day\n• Weekly target: 35mm\n\n**Critical:** Cotton at boll stage needs consistent moisture. Don't let soil dry below 50% field capacity.\n\n**Drip settings:**\n• Flow rate: 2.0 LPH per dripper\n• Spacing: 45cm × 75cm\n• Run time: 40 min = ~12mm irrigation\n\n[Data from: MCP weather_forecast + soil_analysis tools]"
    };
  }

  if (msg.includes("scheme") || msg.includes("subsid") || msg.includes("pm-kisan") || msg.includes("government")) {
    return {
      agent: "scheme_navigator",
      text: "🏛️ **Government Schemes You're Eligible For**\n\nBased on your profile (Small farmer, Telangana, 5.5 acres):\n\n**1. PM-KISAN** ✅ Priority: HIGH\n• Benefit: ₹6,000/year (₹2,000 every 4 months)\n• Documents: Aadhaar + Land Patta + Bank account\n• Apply: pmkisan.gov.in or nearest CSC\n\n**2. PMFBY (Crop Insurance)** ✅ Priority: HIGH\n• Your premium: Only 1.5-2% of sum insured\n• Covers: Pest, drought, flood losses\n• ⚠️ Enroll BEFORE next sowing season\n\n**3. Micro Irrigation Subsidy (PMKSY)** ✅\n• Since you have drip: Get 55% cost reimbursed!\n• Apply through Telangana Horticulture Dept\n\n**4. Kisan Credit Card** ✅\n• Crop loan at 4% interest (govt subsidized)\n• Apply at SBI/cooperative bank with land records\n\n**Next Step:** Start with PM-KISAN registration if not done — easiest and fastest ₹6,000/year!\n\n[Source: MCP government_schemes tool + scheme knowledge base]"
    };
  }

  return {
    agent: "supervisor",
    text: "I understand your query. Let me route this to the right specialist...\n\nAs FarmAI's supervisor, I'm analyzing your question and will connect you with the most relevant expert. In the full system, this routes to:\n\n🌾 Crop Advisor — for planting & fertilizer questions\n🔬 Pest Detector — for disease & pest diagnosis\n📈 Market Analyst — for price & selling decisions\n💧 Irrigation Planner — for water scheduling\n🏛️ Scheme Navigator — for government benefits\n\nTry asking about one of these topics specifically!"
  };
}
