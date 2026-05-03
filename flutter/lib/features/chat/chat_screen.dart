import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/connectivity_watcher.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/voice_service.dart';
import 'message_bubble.dart';
import 'voice_recorder.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  List<Message> _messages = [];
  bool _loading = false;
  bool _isOnline = true;
  bool _isRecording = false;
  String? _farmerId;
  StreamSubscription<bool>? _connectivitySub;

  static const String _defaultLanguage = 'hi';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final auth = context.read<AuthService>();
    final connectivity = context.read<ConnectivityWatcher>();
    final db = context.read<AppDatabase>();

    _farmerId = await auth.getFarmerId();
    _isOnline = await connectivity.isOnline;

    if (_farmerId != null) {
      final stored = await db.getMessages(_farmerId!);
      setState(() {
        _messages = [_welcomeMessage(), ...stored];
      });
    } else {
      setState(() {
        _messages = [_welcomeMessage()];
      });
    }

    _connectivitySub = connectivity.onlineStream.listen((online) {
      setState(() => _isOnline = online);
    });
  }

  Message _welcomeMessage() => Message(
        id: 'welcome',
        farmerId: _farmerId ?? 'demo',
        role: 'assistant',
        content:
            'Namaste! 🙏 I\'m FarmAI — your agricultural advisor.\n\nI can help with:\n• Crop planning\n• Pest diagnosis\n• Market prices\n• Irrigation\n• Government schemes\n\nHold the mic to speak, or type below.',
        agent: 'supervisor',
        createdAt: DateTime.now(),
      );

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _processText(text);
  }

  Future<void> _processText(String text) async {
    final userMsg = Message(
      id: _uuid.v4(),
      farmerId: _farmerId ?? 'demo',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    final db = context.read<AppDatabase>();
    await db.insertMessage(userMsg);

    try {
      final api = context.read<ApiService>();
      final result = await api.textChat(
        farmerId: _farmerId ?? 'demo',
        text: text,
        language: _defaultLanguage,
      );

      final assistantMsg = Message(
        id: _uuid.v4(),
        farmerId: _farmerId ?? 'demo',
        role: 'assistant',
        content: (result['translated_response'] ?? result['text_response']) as String,
        agent: result['agent_used'] as String?,
        audioPath: result['audio_url'] as String?,
        createdAt: DateTime.now(),
      );
      await db.insertMessage(assistantMsg);
      setState(() => _messages.add(assistantMsg));
    } catch (_) {
      final errMsg = Message(
        id: _uuid.v4(),
        farmerId: _farmerId ?? 'demo',
        role: 'assistant',
        content: _isOnline
            ? 'Sorry, something went wrong. Please try again.'
            : 'No connection. Your message will be sent when you\'re back online.',
        agent: 'supervisor',
        createdAt: DateTime.now(),
      );
      setState(() => _messages.add(errMsg));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _startRecording() async {
    final voice = context.read<VoiceService>();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_uuid.v4()}.m4a';
    final started = await voice.startRecording(path);
    if (started) setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final voice = context.read<VoiceService>();
    final path = await voice.stopRecording();
    setState(() => _isRecording = false);
    if (path == null) return;

    final userMsg = Message(
      id: _uuid.v4(),
      farmerId: _farmerId ?? 'demo',
      role: 'user',
      content: '🎤 Voice message',
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    try {
      final api = context.read<ApiService>();
      final db = context.read<AppDatabase>();
      await db.insertMessage(userMsg);

      final result = await api.voiceChat(
        farmerId: _farmerId ?? 'demo',
        audioPath: path,
      );
      final assistantMsg = Message(
        id: _uuid.v4(),
        farmerId: _farmerId ?? 'demo',
        role: 'assistant',
        content: (result['translated_response'] ?? result['text_response']) as String,
        agent: result['agent_used'] as String?,
        audioPath: result['audio_url'] as String?,
        createdAt: DateTime.now(),
      );
      await db.insertMessage(assistantMsg);
      setState(() => _messages.add(assistantMsg));
    } catch (_) {
      final errMsg = Message(
        id: _uuid.v4(),
        farmerId: _farmerId ?? 'demo',
        role: 'assistant',
        content: 'Could not process voice. Please try again.',
        agent: 'supervisor',
        createdAt: DateTime.now(),
      );
      setState(() => _messages.add(errMsg));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!_isOnline)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: const Text(
                '⚡ Offline — messages will be queued',
                style: TextStyle(fontSize: 12, color: Colors.amber),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Agents working...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  );
                }
                return MessageBubble(
                  message: _messages[index],
                  onPlayAudio: _messages[index].audioPath != null
                      ? () => context.read<VoiceService>().playAudio(_messages[index].audioPath!)
                      : null,
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            VoiceRecorder(
              isRecording: _isRecording,
              isSupported: true,
              onStart: _startRecording,
              onStop: _stopRecording,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                onChanged: (_) => setState(() {}),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                decoration: InputDecoration(
                  hintText: 'Ask about crops, pests, prices...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _textController.text.trim().isEmpty ? null : _sendText,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
