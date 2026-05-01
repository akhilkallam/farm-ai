import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/services/storage_service.dart';
import 'package:farmai/models/farmer.dart';
import 'package:farmai/models/message.dart';
import 'package:farmai/models/queued_request.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() {
    db = _inMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('FarmerProfile', () {
    final farmer = Farmer(
      id: 'raju-1',
      name: 'Raju Reddy',
      location: 'Warangal',
      crops: '["cotton","tomato"]',
      landAcres: 5.5,
      updatedAt: DateTime(2026, 1, 1),
    );

    test('upsert and retrieve farmer', () async {
      await db.upsertFarmer(farmer);
      final result = await db.getFarmer('raju-1');
      expect(result?.name, equals('Raju Reddy'));
      expect(result?.landAcres, equals(5.5));
    });

    test('returns null for unknown farmer', () async {
      final result = await db.getFarmer('unknown');
      expect(result, isNull);
    });

    test('upsert updates existing farmer', () async {
      await db.upsertFarmer(farmer);
      final updated = Farmer(
        id: 'raju-1',
        name: 'Raju Updated',
        location: 'Warangal',
        crops: '["wheat"]',
        landAcres: 6.0,
        updatedAt: DateTime(2026, 2, 1),
      );
      await db.upsertFarmer(updated);
      final result = await db.getFarmer('raju-1');
      expect(result?.name, equals('Raju Updated'));
    });
  });

  group('Messages', () {
    test('insert and retrieve messages ordered by createdAt asc', () async {
      final msg1 = Message(
        id: 'msg-1',
        farmerId: 'raju-1',
        role: 'user',
        content: 'Hello',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final msg2 = Message(
        id: 'msg-2',
        farmerId: 'raju-1',
        role: 'assistant',
        content: 'Namaste!',
        agent: 'supervisor',
        createdAt: DateTime(2026, 1, 1, 10, 1),
      );
      await db.insertMessage(msg1);
      await db.insertMessage(msg2);

      final messages = await db.getMessages('raju-1');
      expect(messages.length, equals(2));
      expect(messages.first.role, equals('user'));
      expect(messages.last.agent, equals('supervisor'));
    });

    test('respects limit parameter', () async {
      for (int i = 0; i < 5; i++) {
        await db.insertMessage(Message(
          id: 'msg-$i',
          farmerId: 'raju-1',
          role: 'user',
          content: 'Message $i',
          createdAt: DateTime(2026, 1, 1, i, 0),
        ));
      }
      final messages = await db.getMessages('raju-1', limit: 3);
      expect(messages.length, equals(3));
    });
  });

  group('OfflineQueue', () {
    final req = QueuedRequest(
      id: 'req-1',
      createdAt: DateTime(2026, 1, 1),
      type: QueuedRequestType.text,
      payload: '{"text":"hello","farmer_id":"raju-1"}',
      status: QueuedRequestStatus.pending,
      retryCount: 0,
    );

    test('enqueue and getPendingQueue', () async {
      await db.enqueue(req);
      final pending = await db.getPendingQueue();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('req-1'));
    });

    test('updateQueueItem changes status', () async {
      await db.enqueue(req);
      await db.updateQueueItem('req-1', QueuedRequestStatus.failed, 1);
      final pending = await db.getPendingQueue();
      expect(pending, isEmpty); // status is now 'failed', not 'pending'
    });

    test('deleteQueueItem removes from queue', () async {
      await db.enqueue(req);
      await db.deleteQueueItem('req-1');
      expect(await db.getPendingCount(), equals(0));
    });

    test('getPendingCount returns correct count', () async {
      await db.enqueue(req);
      final req2 = QueuedRequest(
        id: 'req-2',
        createdAt: DateTime(2026, 1, 2),
        type: QueuedRequestType.text,
        payload: '{}',
        status: QueuedRequestStatus.pending,
        retryCount: 0,
      );
      await db.enqueue(req2);
      expect(await db.getPendingCount(), equals(2));
    });
  });
}
