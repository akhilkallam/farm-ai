import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/farmer.dart';
import '../models/message.dart';
import '../models/queued_request.dart';

part 'storage_service.g.dart';

// ─── Drift Table Definitions ──────────────────────────────────────────────────

class FarmerProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  TextColumn get crops => text()();
  RealColumn get landAcres => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ConversationMessages extends Table {
  TextColumn get id => text()();
  TextColumn get farmerId => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get agent => text().nullable()();
  TextColumn get audioPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OfflineQueue extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [FarmerProfiles, ConversationMessages, OfflineQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Farmer profile
  Future<void> upsertFarmer(Farmer farmer) => into(farmerProfiles).insertOnConflictUpdate(
        FarmerProfilesCompanion(
          id: Value(farmer.id),
          name: Value(farmer.name),
          location: Value(farmer.location),
          crops: Value(farmer.crops),
          landAcres: Value(farmer.landAcres),
          updatedAt: Value(farmer.updatedAt),
        ),
      );

  Future<Farmer?> getFarmer(String id) async {
    final row = await (select(farmerProfiles)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return Farmer(
      id: row.id,
      name: row.name,
      location: row.location,
      crops: row.crops,
      landAcres: row.landAcres,
      updatedAt: row.updatedAt,
    );
  }

  // Messages
  Future<void> insertMessage(Message msg) => into(conversationMessages).insertOnConflictUpdate(
        ConversationMessagesCompanion(
          id: Value(msg.id),
          farmerId: Value(msg.farmerId),
          role: Value(msg.role),
          content: Value(msg.content),
          agent: Value(msg.agent),
          audioPath: Value(msg.audioPath),
          createdAt: Value(msg.createdAt),
        ),
      );

  Future<List<Message>> getMessages(String farmerId, {int limit = 20}) async {
    final rows = await (select(conversationMessages)
          ..where((t) => t.farmerId.equals(farmerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows
        .map((r) => Message(
              id: r.id,
              farmerId: r.farmerId,
              role: r.role,
              content: r.content,
              agent: r.agent,
              audioPath: r.audioPath,
              createdAt: r.createdAt,
            ))
        .toList()
        .reversed
        .toList();
  }

  // Offline queue
  Future<void> enqueue(QueuedRequest req) => into(offlineQueue).insert(
        OfflineQueueCompanion(
          id: Value(req.id),
          createdAt: Value(req.createdAt),
          type: Value(req.type.name),
          payload: Value(req.payload),
          status: Value(req.status.name),
          retryCount: Value(req.retryCount),
        ),
      );

  Future<List<QueuedRequest>> getPendingQueue() async {
    final rows = await (select(offlineQueue)
          ..where((t) => t.status.equals(QueuedRequestStatus.pending.name))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_rowToQueuedRequest).toList();
  }

  Future<void> updateQueueItem(String id, QueuedRequestStatus status, int retryCount) =>
      (update(offlineQueue)..where((t) => t.id.equals(id))).write(
        OfflineQueueCompanion(
          status: Value(status.name),
          retryCount: Value(retryCount),
        ),
      );

  Future<void> deleteQueueItem(String id) =>
      (delete(offlineQueue)..where((t) => t.id.equals(id))).go();

  Future<int> getPendingCount() async {
    final count = await (select(offlineQueue)
          ..where((t) => t.status.equals(QueuedRequestStatus.pending.name)))
        .get();
    return count.length;
  }

  QueuedRequest _rowToQueuedRequest(OfflineQueueData r) => QueuedRequest(
        id: r.id,
        createdAt: r.createdAt,
        type: QueuedRequestType.values.byName(r.type),
        payload: r.payload,
        status: QueuedRequestStatus.values.byName(r.status),
        retryCount: r.retryCount,
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'farmai.db'));
    return NativeDatabase.createInBackground(file);
  });
}
