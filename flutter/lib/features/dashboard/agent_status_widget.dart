import 'package:flutter/material.dart';

const _agents = [
  {'key': 'crop_advisor', 'label': 'crop advisor', 'icon': '🌾', 'color': Color(0xFFDCFCE7)},
  {'key': 'pest_detector', 'label': 'pest detector', 'icon': '🔬', 'color': Color(0xFFFFE4E6)},
  {'key': 'market_analyst', 'label': 'market analyst', 'icon': '📈', 'color': Color(0xFFDBEAFE)},
  {'key': 'irrigation_planner', 'label': 'irrigation planner', 'icon': '💧', 'color': Color(0xFFCFFAFE)},
  {'key': 'scheme_navigator', 'label': 'scheme navigator', 'icon': '🏛', 'color': Color(0xFFF3E8FF)},
];

const _mcpTools = [
  '🌤 weather_forecast(location, days)',
  '💰 mandi_prices(crop, state)',
  '🌍 soil_analysis(lat, lon)',
  '🏛 government_schemes(state, crop, category)',
];

class AgentStatusWidget extends StatelessWidget {
  const AgentStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agent System Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._agents.map((agent) => _agentTile(agent)),
        const SizedBox(height: 16),
        _mcpToolsCard(),
      ],
    );
  }

  Widget _agentTile(Map<String, dynamic> agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(agent['icon'] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(agent['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 4),
          const Text('Ready', style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80))),
        ],
      ),
    );
  }

  Widget _mcpToolsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔌 MCP Tools Active',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._mcpTools.map((tool) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tool,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              )),
        ],
      ),
    );
  }
}
