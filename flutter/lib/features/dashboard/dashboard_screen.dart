import 'package:flutter/material.dart';
import 'agent_status_widget.dart';

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(sub,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF166534))),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farm Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: const [
              _StatCard(icon: '🌾', label: 'Current Crops', value: 'Cotton, Tomato', sub: 'Kharif season'),
              _StatCard(icon: '📍', label: 'Location', value: 'Warangal', sub: 'Telangana'),
              _StatCard(icon: '🏞️', label: 'Land', value: '5.5 acres', sub: 'Small farmer'),
              _StatCard(icon: '💧', label: 'Irrigation', value: 'Drip system', sub: 'Installed'),
            ],
          ),
          const SizedBox(height: 24),
          const AgentStatusWidget(),
        ],
      ),
    );
  }
}
