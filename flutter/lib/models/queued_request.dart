enum QueuedRequestType { voice, text }

enum QueuedRequestStatus { pending, sending, failed }

class QueuedRequest {
  final String id;
  final DateTime createdAt;
  final QueuedRequestType type;
  final String payload; // JSON: {audio_path, language, farmer_id} or {text, farmer_id}
  final QueuedRequestStatus status;
  final int retryCount;

  const QueuedRequest({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.payload,
    required this.status,
    required this.retryCount,
  });

  QueuedRequest copyWith({QueuedRequestStatus? status, int? retryCount}) {
    return QueuedRequest(
      id: id,
      createdAt: createdAt,
      type: type,
      payload: payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
