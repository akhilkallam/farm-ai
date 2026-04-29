'use client'
import { AGENT_ICONS } from '@/lib/agentConfig'

const MCP_TOOLS = [
  '🌤 weather_forecast(location, days)',
  '💰 mandi_prices(crop, state)',
  '🌍 soil_analysis(lat, lon)',
  '🏛 government_schemes(state, crop, category)',
]

export default function AgentStatus() {
  return (
    <div className="space-y-4 mt-6">
      <h2 className="text-lg font-bold text-gray-700">Agent System Status</h2>
      <div className="space-y-2">
        {Object.entries(AGENT_ICONS)
          .filter(([agent]) => agent !== 'supervisor')
          .map(([agent, icon]) => (
            <div
              key={agent}
              className="bg-white rounded-xl p-3 shadow-sm border border-gray-100 flex items-center justify-between"
            >
              <div className="flex items-center gap-2">
                <span>{icon}</span>
                <span className="text-sm font-medium text-gray-700 capitalize">
                  {agent.replace(/_/g, ' ')}
                </span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 bg-green-400 rounded-full" />
                <span className="text-xs text-green-600">Ready</span>
              </div>
            </div>
          ))}
      </div>

      <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
        <h3 className="font-bold text-gray-700 mb-2">🔌 MCP Tools Active</h3>
        <div className="space-y-2">
          {MCP_TOOLS.map((tool) => (
            <div key={tool} className="text-xs text-gray-600 font-mono bg-gray-50 px-2 py-1 rounded">
              {tool}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
