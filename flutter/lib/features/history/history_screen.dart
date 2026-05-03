import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Message> _messages = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final db = context.read<AppDatabase>();
    final farmerId = await auth.getFarmerId();
    if (!mounted) return;
    if (farmerId == null) {
      setState(() => _loaded = true);
      return;
    }
    final msgs = await db.getMessages(farmerId, limit: 50);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌾', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No conversations yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 4),
            Text('Your chat history will appear here.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return Material(
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: msg.role == 'user'
                ? const Color(0xFF166534)
                : const Color(0xFFDCFCE7),
            child: Text(
              msg.role == 'user' ? '👨‍🌾' : '🌱',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          title: Text(
            msg.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            '${msg.createdAt.day}/${msg.createdAt.month}/${msg.createdAt.year} '
            '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        );
      },
    ),
    );
  }
}
