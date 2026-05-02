import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';
import '../models/queued_request.dart';

class SyncService {
  final ApiService _api;
  final AppDatabase _db;

  static const int _maxRetries = 3;

  SyncService({required ApiService api, required AppDatabase db})
      : _api = api,
        _db = db;

  /// Flush all pending queue items to the BFF.
  /// On success: delete from queue.
  /// On failure: increment retryCount. Mark as failed at maxRetries.
  Future<void> flushQueue() async {
    final pending = await _db.getPendingQueue();
    if (pending.isEmpty) return;

    // Mark all as 'sending'
    for (final req in pending) {
      await _db.updateQueueItem(req.id, QueuedRequestStatus.sending, req.retryCount);
    }

    try {
      final batch = pending.map((r) {
        final payload = jsonDecode(r.payload) as Map<String, dynamic>;
        return {
          'id': r.id,
          'type': r.type.name,
          ...payload,
          'queued_at': r.createdAt.toIso8601String(),
        };
      }).toList();

      final response = await _api.syncPush(batch);
      final results = (response['results'] as List).cast<Map<String, dynamic>>();

      for (final result in results) {
        if (result['success'] == true) {
          await _db.deleteQueueItem(result['id'] as String);
        }
      }
    } catch (_) {
      // On failure: increment retryCount, mark failed if maxed
      for (final req in pending) {
        final newCount = req.retryCount + 1;
        final newStatus = newCount >= _maxRetries
            ? QueuedRequestStatus.failed
            : QueuedRequestStatus.pending;
        await _db.updateQueueItem(req.id, newStatus, newCount);
      }
    }
  }
}
