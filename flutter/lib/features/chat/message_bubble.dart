import 'package:flutter/material.dart';
import '../../models/message.dart';

const _agentLabels = {
  'crop_advisor': 'crop advisor',
  'pest_detector': 'pest detector',
  'market_analyst': 'market analyst',
  'irrigation_planner': 'irrigation planner',
  'scheme_navigator': 'scheme navigator',
  'supervisor': 'supervisor',
};

const _agentColors = {
  'crop_advisor': Color(0xFFDCFCE7),
  'pest_detector': Color(0xFFFFE4E6),
  'market_analyst': Color(0xFFDBEAFE),
  'irrigation_planner': Color(0xFFCFFAFE),
  'scheme_navigator': Color(0xFFF3E8FF),
  'supervisor': Color(0xFFF3F4F6),
};

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onPlayAudio;

  const MessageBubble({super.key, required this.message, this.onPlayAudio});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) _avatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isUser ? const Color(0xFF166534) : Colors.white,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: _isUser ? const Radius.circular(4) : null,
                      bottomLeft: !_isUser ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: _isUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      if (message.audioPath != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onPlayAudio,
                          child: const Icon(Icons.play_circle_outline,
                              size: 28, color: Color(0xFF166534)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (message.agent != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _agentColors[message.agent] ?? const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _agentLabels[message.agent] ?? message.agent!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isUser) _userAvatar(),
        ],
      ),
    );
  }

  Widget _avatar() => const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFF166534),
        child: Text('🌱', style: TextStyle(fontSize: 14)),
      );

  Widget _userAvatar() => const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFF14532D),
        child: Text('👨‍🌾', style: TextStyle(fontSize: 14)),
      );
}
