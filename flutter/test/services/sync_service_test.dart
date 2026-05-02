import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farmai/services/api_service.dart';
import 'package:farmai/services/storage_service.dart';
import 'package:farmai/services/sync_service.dart';
import 'package:farmai/models/queued_request.dart';

class MockApiService extends Mock implements ApiService {}

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late MockApiService mockApi;
  late AppDatabase db;
  late SyncService syncService;

  setUp(() {
    mockApi = MockApiService();
    db = _inMemoryDb();
    syncService = SyncService(api: mockApi, db: db);
  });

  tearDown(() async {
    await db.close();
  });

  final pendingReq = QueuedRequest(
    id: 'req-1',
    createdAt: DateTime(2026, 1, 1),
    type: QueuedRequestType.text,
    payload: '{"text":"hello","farmer_id":"raju-1","language":"hi"}',
    status: QueuedRequestStatus.pending,
    retryCount: 0,
  );

  test('flushQueue sends pending items and deletes on success', () async {
    await db.enqueue(pendingReq);

    when(() => mockApi.syncPush(any())).thenAnswer((_) async => {
          'results': [
            {'id': 'req-1', 'success': true, 'response': {'text_response': 'ok'}}
          ],
        });

    await syncService.flushQueue();

    verify(() => mockApi.syncPush(any())).called(1);
    expect(await db.getPendingCount(), equals(0));
  });

  test('flushQueue increments retryCount on failure', () async {
    await db.enqueue(pendingReq);

    when(() => mockApi.syncPush(any())).thenThrow(Exception('network error'));

    await syncService.flushQueue();

    // After 1 failure with retryCount=0, newCount=1, maxRetries=3 → stays pending? No:
    // newCount (1) >= maxRetries (3)? No → status=pending, retryCount=1
    // But getPendingQueue filters by 'pending', so it should still be there with retryCount=1
    final all = await (db.select(db.offlineQueue)).get();
    expect(all.first.retryCount, equals(1));
    // After 1 failure from retryCount=0, it should be pending (not failed yet)
    expect(all.first.status, equals('pending'));
  });

  test('flushQueue marks item as failed after maxRetries', () async {
    final maxedReq = QueuedRequest(
      id: 'req-2',
      createdAt: DateTime(2026, 1, 1),
      type: QueuedRequestType.text,
      payload: '{}',
      status: QueuedRequestStatus.pending,
      retryCount: 2, // already at 2, next failure → 3 = maxRetries → failed
    );
    await db.enqueue(maxedReq);

    when(() => mockApi.syncPush(any())).thenThrow(Exception('network error'));

    await syncService.flushQueue();

    final all = await (db.select(db.offlineQueue)).get();
    expect(all.first.status, equals('failed'));
  });

  test('flushQueue is no-op when queue is empty', () async {
    await syncService.flushQueue();
    verifyNever(() => mockApi.syncPush(any()));
  });
}
