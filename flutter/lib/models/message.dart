class Message {
  final String id;
  final String farmerId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? agent;
  final String? audioPath; // local file path or remote URL
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.farmerId,
    required this.role,
    required this.content,
    this.agent,
    this.audioPath,
    required this.createdAt,
  });
}
