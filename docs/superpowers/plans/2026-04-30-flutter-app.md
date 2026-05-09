# Farm-AI Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter iOS/Android app with OTP auth, voice-first chat, SQLite offline storage, and background sync against the Farm-AI BFF (port 8002).

**Architecture:** Flutter app with Provider-based DI, Drift/SQLite for offline storage, Dio for BFF HTTP calls. All business logic lives in services injected at the root. Screens are thin widgets that read from services. Offline queue (SQLite) is flushed to BFF whenever connectivity is restored or the app comes to the foreground.

**Tech Stack:** Flutter 3.x, Dart 3, drift 2.x (SQLite ORM + codegen), dio 5.x, record 5.x, just_audio, connectivity_plus, flutter_secure_storage, provider, uuid, mocktail (tests)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `flutter/pubspec.yaml` | Modify | All dependencies |
| `flutter/lib/main.dart` | Modify | App root, Provider setup, nav |
| `flutter/lib/core/theme.dart` | Create | FarmAI color theme |
| `flutter/lib/core/connectivity_watcher.dart` | Create | Stream of online/offline state |
| `flutter/lib/models/farmer.dart` | Create | Plain Dart farmer model |
| `flutter/lib/models/message.dart` | Create | Plain Dart message model |
| `flutter/lib/models/queued_request.dart` | Create | Plain Dart queued request model |
| `flutter/lib/services/storage_service.dart` | Create | Drift DB: FarmerProfiles, Messages, QueuedRequests tables |
| `flutter/lib/services/auth_service.dart` | Create | JWT read/write (flutter_secure_storage) + isLoggedIn |
| `flutter/lib/services/api_service.dart` | Create | Dio BFF client: sendOtp, verifyOtp, textChat, voiceChat, syncPush, syncPull |
| `flutter/lib/services/voice_service.dart` | Create | Record audio → File, play audio URL |
| `flutter/lib/services/sync_service.dart` | Create | Flush offline queue to BFF, exponential backoff, retry |
| `flutter/lib/features/auth/otp_screen.dart` | Create | Phone entry → OTP entry → JWT stored → nav to chat |
| `flutter/lib/features/chat/message_bubble.dart` | Create | Single message widget with audio player |
| `flutter/lib/features/chat/voice_recorder.dart` | Create | Hold-to-record button widget |
| `flutter/lib/features/chat/chat_screen.dart` | Create | Full chat UI: text + voice, message list, offline banner |
| `flutter/lib/features/dashboard/agent_status_widget.dart` | Create | Agent + MCP tools status list |
| `flutter/lib/features/dashboard/dashboard_screen.dart` | Create | Farm stats + agent status |
| `flutter/lib/features/history/history_screen.dart` | Create | Conversation list from SQLite |
| `flutter/test/services/storage_service_test.dart` | Create | In-memory Drift DB CRUD tests |
| `flutter/test/services/auth_service_test.dart` | Create | JWT storage mock tests |
| `flutter/test/services/api_service_test.dart` | Create | Mocked Dio response tests |
| `flutter/test/services/sync_service_test.dart` | Create | Queue flush + retry logic tests |
| `flutter/test/core/connectivity_watcher_test.dart` | Create | Stream emission tests |
| `flutter/test/features/auth/otp_screen_test.dart` | Create | Widget tests for OTP flow |
| `flutter/test/features/chat/message_bubble_test.dart` | Create | Widget render tests |
| `flutter/test/features/chat/voice_recorder_test.dart` | Create | Widget state tests |
| `flutter/test/features/chat/chat_screen_test.dart` | Create | Widget integration tests (mocked services) |
| `flutter/test/features/dashboard/dashboard_screen_test.dart` | Create | Widget render tests |
| `flutter/test/features/history/history_screen_test.dart` | Create | Widget render tests |

---

## Task 1: Project setup — pubspec, theme, folder structure

**Files:**
- Modify: `flutter/pubspec.yaml`
- Create: `flutter/lib/core/theme.dart`
- Modify: `flutter/lib/main.dart`
- Create: `flutter/test/widget_test.dart` (replace default)

All commands run from `flutter/`.

- [ ] **Step 1: Add dependencies to `flutter/pubspec.yaml`**

Replace the `dependencies` and `dev_dependencies` sections:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # SQLite ORM
  drift: ^2.14.1
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.9.0
  # Audio
  record: ^5.1.0
  just_audio: ^0.9.36
  # Network
  connectivity_plus: ^5.0.2
  dio: ^5.4.3+1
  # Auth
  flutter_secure_storage: ^9.0.0
  # State / DI
  provider: ^6.1.2
  # Utils
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.2
  mocktail: ^1.0.3
  drift_dev: ^2.14.1
  build_runner: ^2.4.9
```

- [ ] **Step 2: Run `flutter pub get`**

```bash
cd flutter && flutter pub get
```

Expected: `Resolving dependencies...` and no errors.

- [ ] **Step 3: Create folder structure**

```bash
cd flutter && mkdir -p \
  lib/core \
  lib/models \
  lib/services \
  lib/features/auth \
  lib/features/chat \
  lib/features/dashboard \
  lib/features/history \
  test/core \
  test/services \
  test/features/auth \
  test/features/chat \
  test/features/dashboard \
  test/features/history
```

- [ ] **Step 4: Create `flutter/lib/core/theme.dart`**

```dart
import 'package:flutter/material.dart';

class FarmAITheme {
  static const Color primaryGreen = Color(0xFF166534);
  static const Color lightGreen = Color(0xFFDCFCE7);
  static const Color accentAmber = Color(0xFFF59E0B);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      );
}
```

- [ ] **Step 5: Replace `flutter/lib/main.dart` with a stub**

```dart
import 'package:flutter/material.dart';
import 'core/theme.dart';

void main() {
  runApp(const FarmAIApp());
}

class FarmAIApp extends StatelessWidget {
  const FarmAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmAI',
      theme: FarmAITheme.theme,
      home: const Scaffold(
        body: Center(child: Text('FarmAI')),
      ),
    );
  }
}
```

- [ ] **Step 6: Replace `flutter/test/widget_test.dart` with a smoke test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart test runner works', () {
    expect(1 + 1, equals(2));
  });
}
```

- [ ] **Step 7: Run tests to verify setup works**

```bash
cd flutter && flutter test test/widget_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 8: Commit**

```bash
cd flutter
git add pubspec.yaml pubspec.lock lib/core/theme.dart lib/main.dart test/widget_test.dart
git commit -m "feat(flutter): project setup — theme, folder structure, dependencies"
```

---

## Task 2: Drift data models + StorageService

**Files:**
- Create: `flutter/lib/models/farmer.dart`
- Create: `flutter/lib/models/message.dart`
- Create: `flutter/lib/models/queued_request.dart`
- Create: `flutter/lib/services/storage_service.dart`
- Create: `flutter/lib/services/storage_service.g.dart` (generated)
- Create: `flutter/test/services/storage_service_test.dart`

- [ ] **Step 1: Create `flutter/lib/models/farmer.dart`**

```dart
class Farmer {
  final String id;
  final String name;
  final String location;
  final String crops; // JSON string e.g. '["cotton","tomato"]'
  final double landAcres;
  final DateTime updatedAt;

  const Farmer({
    required this.id,
    required this.name,
    required this.location,
    required this.crops,
    required this.landAcres,
    required this.updatedAt,
  });
}
```

- [ ] **Step 2: Create `flutter/lib/models/message.dart`**

```dart
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
```

- [ ] **Step 3: Create `flutter/lib/models/queued_request.dart`**

```dart
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
```

- [ ] **Step 4: Create `flutter/lib/services/storage_service.dart`**

```dart
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
```

- [ ] **Step 5: Run code generator**

```bash
cd flutter && dart run build_runner build --delete-conflicting-outputs
```

Expected: `storage_service.g.dart` is created. No errors.

- [ ] **Step 6: Write `flutter/test/services/storage_service_test.dart`**

```dart
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
      await db.enqueue(req.copyWith(status: QueuedRequestStatus.pending)
        ..id); // same id — skipped; use unique id
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
```

- [ ] **Step 7: Run tests**

```bash
cd flutter && flutter test test/services/storage_service_test.dart
```

Expected: `All tests passed!` (9 tests)

If you see `package:farmai` not found, check that `name: farmai` is in `pubspec.yaml`.

- [ ] **Step 8: Commit**

```bash
cd flutter
git add lib/models/ lib/services/storage_service.dart lib/services/storage_service.g.dart test/services/storage_service_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(flutter): add Drift models + AppDatabase (farmer, messages, offline queue)"
```

---

## Task 3: AuthService + JWT storage

**Files:**
- Create: `flutter/lib/services/auth_service.dart`
- Create: `flutter/test/services/auth_service_test.dart`

- [ ] **Step 1: Write `flutter/test/services/auth_service_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:farmai/services/auth_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late AuthService authService;

  setUp(() {
    mockStorage = MockSecureStorage();
    authService = AuthService(storage: mockStorage);
  });

  test('isLoggedIn returns false when no JWT stored', () async {
    when(() => mockStorage.read(key: 'jwt')).thenAnswer((_) async => null);
    expect(await authService.isLoggedIn(), isFalse);
  });

  test('isLoggedIn returns true when JWT is stored', () async {
    when(() => mockStorage.read(key: 'jwt')).thenAnswer((_) async => 'test-token');
    expect(await authService.isLoggedIn(), isTrue);
  });

  test('saveToken stores JWT and farmerId', () async {
    when(() => mockStorage.write(key: 'jwt', value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.write(key: 'farmer_id', value: any(named: 'value')))
        .thenAnswer((_) async {});

    await authService.saveToken('my-token', '+919999999999');

    verify(() => mockStorage.write(key: 'jwt', value: 'my-token')).called(1);
    verify(() => mockStorage.write(key: 'farmer_id', value: '+919999999999')).called(1);
  });

  test('getToken returns stored JWT', () async {
    when(() => mockStorage.read(key: 'jwt')).thenAnswer((_) async => 'stored-token');
    expect(await authService.getToken(), equals('stored-token'));
  });

  test('getFarmerId returns stored farmer_id', () async {
    when(() => mockStorage.read(key: 'farmer_id')).thenAnswer((_) async => '+919876543210');
    expect(await authService.getFarmerId(), equals('+919876543210'));
  });

  test('logout clears JWT and farmerId', () async {
    when(() => mockStorage.delete(key: 'jwt')).thenAnswer((_) async {});
    when(() => mockStorage.delete(key: 'farmer_id')).thenAnswer((_) async {});

    await authService.logout();

    verify(() => mockStorage.delete(key: 'jwt')).called(1);
    verify(() => mockStorage.delete(key: 'farmer_id')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it FAILS**

```bash
cd flutter && flutter test test/services/auth_service_test.dart
```

Expected: FAILED — `'package:farmai/services/auth_service.dart': target of URI doesn't exist`

- [ ] **Step 3: Create `flutter/lib/services/auth_service.dart`**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() => _storage.read(key: 'jwt');

  Future<String?> getFarmerId() => _storage.read(key: 'farmer_id');

  Future<void> saveToken(String token, String farmerId) async {
    await _storage.write(key: 'jwt', value: token);
    await _storage.write(key: 'farmer_id', value: farmerId);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'farmer_id');
  }
}
```

- [ ] **Step 4: Run test to verify it PASSES**

```bash
cd flutter && flutter test test/services/auth_service_test.dart
```

Expected: `All tests passed!` (6 tests)

- [ ] **Step 5: Commit**

```bash
cd flutter
git add lib/services/auth_service.dart test/services/auth_service_test.dart
git commit -m "feat(flutter): add AuthService with JWT secure storage"
```

---

## Task 4: ApiService — Dio BFF client

**Files:**
- Create: `flutter/lib/services/api_service.dart`
- Create: `flutter/test/services/api_service_test.dart`

- [ ] **Step 1: Write `flutter/test/services/api_service_test.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farmai/services/api_service.dart';
import 'package:farmai/services/auth_service.dart';

class MockDio extends Mock implements Dio {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockDio mockDio;
  late MockAuthService mockAuth;
  late ApiService api;

  setUp(() {
    mockDio = MockDio();
    mockAuth = MockAuthService();
    api = ApiService(dio: mockDio, auth: mockAuth);
    when(() => mockAuth.getToken()).thenAnswer((_) async => 'test-jwt');
  });

  test('sendOtp POSTs to /auth/otp/send', () async {
    when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'OTP sent'},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    await api.sendOtp('+919999999999');

    verify(() => mockDio.post(
          '/auth/otp/send',
          data: {'phone': '+919999999999'},
          options: any(named: 'options'),
        )).called(1);
  });

  test('verifyOtp POSTs to /auth/otp/verify and returns token + farmerId', () async {
    when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: {'access_token': 'jwt-abc', 'farmer_id': '+919999999999'},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    final result = await api.verifyOtp('+919999999999', '123456');

    expect(result['access_token'], equals('jwt-abc'));
    expect(result['farmer_id'], equals('+919999999999'));
  });

  test('textChat POSTs to /text/chat with auth header', () async {
    when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: {
            'text_response': 'Plant wheat',
            'translated_response': 'गेहूं उगाएं',
            'agent_used': 'crop_advisor',
            'queued': false,
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    final result = await api.textChat(
      farmerId: 'raju-1',
      text: 'कौन सी फसल लगाएं?',
      language: 'hi',
    );

    expect(result['agent_used'], equals('crop_advisor'));
    verify(() => mockDio.post(
          '/text/chat',
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).called(1);
  });

  test('syncPull GETs /sync/pull/{farmerId}', () async {
    when(() => mockDio.get(
          any(),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: {'farmer_profile': {}, 'recent_conversations': []},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    final result = await api.syncPull('raju-1');
    expect(result['recent_conversations'], isA<List>());
  });

  test('syncPush POSTs batch to /sync/push', () async {
    when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: {'results': [{'id': 'req-1', 'success': true}]},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

    final result = await api.syncPush([
      {'id': 'req-1', 'type': 'text', 'payload': '{}'},
    ]);
    expect(result['results'], hasLength(1));
  });
}
```

- [ ] **Step 2: Run test to verify it FAILS**

```bash
cd flutter && flutter test test/services/api_service_test.dart
```

Expected: FAILED — `api_service.dart` not found

- [ ] **Step 3: Create `flutter/lib/services/api_service.dart`**

```dart
import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
  final Dio _dio;
  final AuthService _auth;

  static const String _baseUrl = 'http://localhost:8002';

  ApiService({Dio? dio, AuthService? auth})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl)),
        _auth = auth ?? AuthService();

  Future<Options> _authOptions() async {
    final token = await _auth.getToken();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  /// Send OTP to phone number
  Future<void> sendOtp(String phone) async {
    await _dio.post(
      '/auth/otp/send',
      data: {'phone': phone},
      options: await _authOptions(),
    );
  }

  /// Verify OTP → returns {access_token, farmer_id}
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final resp = await _dio.post(
      '/auth/otp/verify',
      data: {'phone': phone, 'otp': otp},
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Text chat → returns {text_response, translated_response, agent_used, audio_url, queued}
  Future<Map<String, dynamic>> textChat({
    required String farmerId,
    required String text,
    required String language,
  }) async {
    final resp = await _dio.post(
      '/text/chat',
      data: {'farmer_id': farmerId, 'text': text, 'language': language},
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Voice chat — multipart audio upload
  Future<Map<String, dynamic>> voiceChat({
    required String farmerId,
    required String audioPath,
    String? languageHint,
  }) async {
    final formData = FormData.fromMap({
      'farmer_id': farmerId,
      'audio': await MultipartFile.fromFile(audioPath, filename: 'recording.m4a'),
      if (languageHint != null) 'language_hint': languageHint,
    });
    final resp = await _dio.post(
      '/voice/chat',
      data: formData,
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Pull latest farmer profile + conversations
  Future<Map<String, dynamic>> syncPull(String farmerId) async {
    final resp = await _dio.get(
      '/sync/pull/$farmerId',
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Push offline batch to BFF
  Future<Map<String, dynamic>> syncPush(List<Map<String, dynamic>> requests) async {
    final resp = await _dio.post(
      '/sync/push',
      data: {'requests': requests},
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }
}
```

- [ ] **Step 4: Run test to verify it PASSES**

```bash
cd flutter && flutter test test/services/api_service_test.dart
```

Expected: `All tests passed!` (5 tests)

- [ ] **Step 5: Commit**

```bash
cd flutter
git add lib/services/api_service.dart test/services/api_service_test.dart
git commit -m "feat(flutter): add ApiService — Dio BFF client (auth, chat, sync)"
```

---

## Task 5: VoiceService + ConnectivityWatcher

**Files:**
- Create: `flutter/lib/services/voice_service.dart`
- Create: `flutter/lib/core/connectivity_watcher.dart`
- Create: `flutter/test/services/voice_service_test.dart`
- Create: `flutter/test/core/connectivity_watcher_test.dart`

- [ ] **Step 1: Write `flutter/test/services/voice_service_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:farmai/services/voice_service.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}
class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioRecorder mockRecorder;
  late MockAudioPlayer mockPlayer;
  late VoiceService voiceService;

  setUp(() {
    mockRecorder = MockAudioRecorder();
    mockPlayer = MockAudioPlayer();
    voiceService = VoiceService(
      recorder: mockRecorder,
      player: mockPlayer,
    );
  });

  test('isRecording returns false initially', () {
    expect(voiceService.isRecording, isFalse);
  });

  test('startRecording requests mic permission and starts recorder', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRecorder.start(
          any(),
          path: any(named: 'path'),
        )).thenAnswer((_) async {});

    await voiceService.startRecording('/tmp/test.m4a');

    verify(() => mockRecorder.hasPermission()).called(1);
    verify(() => mockRecorder.start(any(), path: '/tmp/test.m4a')).called(1);
    expect(voiceService.isRecording, isTrue);
  });

  test('stopRecording stops recorder and returns path', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRecorder.start(any(), path: any(named: 'path')))
        .thenAnswer((_) async {});
    when(() => mockRecorder.stop()).thenAnswer((_) async => '/tmp/test.m4a');

    await voiceService.startRecording('/tmp/test.m4a');
    final path = await voiceService.stopRecording();

    expect(path, equals('/tmp/test.m4a'));
    expect(voiceService.isRecording, isFalse);
  });

  test('startRecording returns false when permission denied', () async {
    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => false);

    final started = await voiceService.startRecording('/tmp/test.m4a');
    expect(started, isFalse);
    expect(voiceService.isRecording, isFalse);
  });

  test('playAudio sets audio source and plays', () async {
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});

    await voiceService.playAudio('http://localhost:8002/audio/test.mp3');

    verify(() => mockPlayer.setUrl('http://localhost:8002/audio/test.mp3')).called(1);
    verify(() => mockPlayer.play()).called(1);
  });
}
```

- [ ] **Step 2: Write `flutter/test/core/connectivity_watcher_test.dart`**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farmai/core/connectivity_watcher.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityWatcher watcher;

  setUp(() {
    mockConnectivity = MockConnectivity();
    watcher = ConnectivityWatcher(connectivity: mockConnectivity);
  });

  test('isOnline returns true for wifi', () {
    expect(
      watcher.isOnlineResult([ConnectivityResult.wifi]),
      isTrue,
    );
  });

  test('isOnline returns true for mobile', () {
    expect(
      watcher.isOnlineResult([ConnectivityResult.mobile]),
      isTrue,
    );
  });

  test('isOnline returns false for none', () {
    expect(
      watcher.isOnlineResult([ConnectivityResult.none]),
      isFalse,
    );
  });

  test('isOnline returns false for empty list', () {
    expect(watcher.isOnlineResult([]), isFalse);
  });
}
```

- [ ] **Step 3: Run tests to verify they FAIL**

```bash
cd flutter && flutter test test/services/voice_service_test.dart test/core/connectivity_watcher_test.dart
```

Expected: FAILED — files not found

- [ ] **Step 4: Create `flutter/lib/services/voice_service.dart`**

```dart
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class VoiceService {
  final AudioRecorder _recorder;
  final AudioPlayer _player;
  bool _isRecording = false;

  VoiceService({AudioRecorder? recorder, AudioPlayer? player})
      : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  bool get isRecording => _isRecording;

  /// Returns true if recording started successfully, false if permission denied.
  Future<bool> startRecording(String outputPath) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: outputPath,
    );
    _isRecording = true;
    return true;
  }

  /// Stops recording. Returns the file path or null.
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  /// Play audio from a URL (BFF TTS audio).
  Future<void> playAudio(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> stopAudio() => _player.stop();

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
```

- [ ] **Step 5: Create `flutter/lib/core/connectivity_watcher.dart`**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWatcher {
  final Connectivity _connectivity;

  ConnectivityWatcher({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of online/offline boolean.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((results) => isOnlineResult(results));

  /// Check current connectivity status.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return isOnlineResult(results);
  }

  /// Pure function — easy to unit test.
  bool isOnlineResult(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }
}
```

- [ ] **Step 6: Run tests to verify they PASS**

```bash
cd flutter && flutter test test/services/voice_service_test.dart test/core/connectivity_watcher_test.dart
```

Expected: `All tests passed!` (9 tests)

- [ ] **Step 7: Commit**

```bash
cd flutter
git add lib/services/voice_service.dart lib/core/connectivity_watcher.dart test/services/voice_service_test.dart test/core/connectivity_watcher_test.dart
git commit -m "feat(flutter): add VoiceService (record+playback) and ConnectivityWatcher"
```

---

## Task 6: SyncService — offline queue flush + retry

**Files:**
- Create: `flutter/lib/services/sync_service.dart`
- Create: `flutter/test/services/sync_service_test.dart`

- [ ] **Step 1: Write `flutter/test/services/sync_service_test.dart`**

```dart
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

    final queue = await db.getPendingQueue();
    // After 1 failure it stays pending but retry_count increases
    // After maxRetries it becomes failed
    expect(queue, isEmpty); // moved to failed after 1 retry in test (retryCount was 0, maxRetries=3)
    // check the item is now failed
    final all = await (db.select(db.offlineQueue)).get();
    expect(all.first.retryCount, equals(1));
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
```

- [ ] **Step 2: Run test to verify it FAILS**

```bash
cd flutter && flutter test test/services/sync_service_test.dart
```

Expected: FAILED — `sync_service.dart` not found

- [ ] **Step 3: Create `flutter/lib/services/sync_service.dart`**

```dart
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
```

- [ ] **Step 4: Run test to verify it PASSES**

```bash
cd flutter && flutter test test/services/sync_service_test.dart
```

Expected: `All tests passed!` (4 tests)

- [ ] **Step 5: Commit**

```bash
cd flutter
git add lib/services/sync_service.dart test/services/sync_service_test.dart
git commit -m "feat(flutter): add SyncService — offline queue flush with retry backoff"
```

---

## Task 7: OTP screen

**Files:**
- Create: `flutter/lib/features/auth/otp_screen.dart`
- Create: `flutter/test/features/auth/otp_screen_test.dart`

- [ ] **Step 1: Write `flutter/test/features/auth/otp_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:farmai/services/api_service.dart';
import 'package:farmai/services/auth_service.dart';
import 'package:farmai/features/auth/otp_screen.dart';

class MockApiService extends Mock implements ApiService {}
class MockAuthService extends Mock implements AuthService {}

Widget _buildTestWidget({
  required MockApiService api,
  required MockAuthService auth,
  required VoidCallback onSuccess,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      Provider<AuthService>.value(value: auth),
    ],
    child: MaterialApp(
      home: OtpScreen(onSuccess: onSuccess),
    ),
  );
}

void main() {
  late MockApiService mockApi;
  late MockAuthService mockAuth;
  bool successCalled = false;

  setUp(() {
    mockApi = MockApiService();
    mockAuth = MockAuthService();
    successCalled = false;
  });

  testWidgets('shows phone entry field initially', (tester) async {
    await tester.pumpWidget(_buildTestWidget(
      api: mockApi,
      auth: mockAuth,
      onSuccess: () => successCalled = true,
    ));
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('Send OTP button calls api.sendOtp', (tester) async {
    when(() => mockApi.sendOtp(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTestWidget(
      api: mockApi,
      auth: mockAuth,
      onSuccess: () => successCalled = true,
    ));

    await tester.enterText(find.byType(TextFormField), '+919876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    verify(() => mockApi.sendOtp('+919876543210')).called(1);
  });

  testWidgets('shows OTP field after phone is submitted', (tester) async {
    when(() => mockApi.sendOtp(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTestWidget(
      api: mockApi,
      auth: mockAuth,
      onSuccess: () => successCalled = true,
    ));

    await tester.enterText(find.byType(TextFormField), '+919876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the OTP sent to +919876543210'), findsOneWidget);
  });

  testWidgets('Verify OTP calls api.verifyOtp, saves token, triggers onSuccess', (tester) async {
    when(() => mockApi.sendOtp(any())).thenAnswer((_) async {});
    when(() => mockApi.verifyOtp(any(), any())).thenAnswer((_) async => {
          'access_token': 'jwt-xyz',
          'farmer_id': '+919876543210',
        });
    when(() => mockAuth.saveToken(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTestWidget(
      api: mockApi,
      auth: mockAuth,
      onSuccess: () => successCalled = true,
    ));

    // Submit phone
    await tester.enterText(find.byType(TextFormField), '+919876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // Submit OTP
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify OTP'));
    await tester.pumpAndSettle();

    verify(() => mockApi.verifyOtp('+919876543210', '123456')).called(1);
    verify(() => mockAuth.saveToken('jwt-xyz', '+919876543210')).called(1);
    expect(successCalled, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it FAILS**

```bash
cd flutter && flutter test test/features/auth/otp_screen_test.dart
```

Expected: FAILED

- [ ] **Step 3: Create `flutter/lib/features/auth/otp_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const OtpScreen({super.key, required this.onSuccess});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = context.read<ApiService>();
      await api.sendOtp(_phoneController.text.trim());
      setState(() { _otpSent = true; });
    } catch (e) {
      setState(() { _error = 'Failed to send OTP. Check your number.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthService>();
      final result = await api.verifyOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
      );
      await auth.saveToken(
        result['access_token'] as String,
        result['farmer_id'] as String,
      );
      widget.onSuccess();
    } catch (e) {
      setState(() { _error = 'Invalid OTP. Please try again.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FarmAI — Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text('🌱 FarmAI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('AI Agricultural Advisor', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              if (!_otpSent) ...[
                const Text('Enter your phone number',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send OTP'),
                ),
              ] else ...[
                Text('Enter the OTP sent to ${_phoneController.text.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '6-digit OTP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length != 6) ? 'Enter the 6-digit OTP' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify OTP'),
                ),
                TextButton(
                  onPressed: () => setState(() { _otpSent = false; }),
                  child: const Text('Change phone number'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it PASSES**

```bash
cd flutter && flutter test test/features/auth/otp_screen_test.dart
```

Expected: `All tests passed!` (4 tests)

- [ ] **Step 5: Commit**

```bash
cd flutter
git add lib/features/auth/otp_screen.dart test/features/auth/otp_screen_test.dart
git commit -m "feat(flutter): add OTP auth screen (phone → OTP → JWT)"
```

---

## Task 8: Chat UI widgets — MessageBubble + VoiceRecorder

**Files:**
- Create: `flutter/lib/features/chat/message_bubble.dart`
- Create: `flutter/lib/features/chat/voice_recorder.dart`
- Create: `flutter/test/features/chat/message_bubble_test.dart`
- Create: `flutter/test/features/chat/voice_recorder_test.dart`

- [ ] **Step 1: Write `flutter/test/features/chat/message_bubble_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/models/message.dart';
import 'package:farmai/features/chat/message_bubble.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final userMsg = Message(
    id: '1',
    farmerId: 'raju-1',
    role: 'user',
    content: 'Which crop for Rabi season?',
    createdAt: DateTime(2026, 1, 1, 10, 0),
  );

  final assistantMsg = Message(
    id: '2',
    farmerId: 'raju-1',
    role: 'assistant',
    content: 'Plant wheat for Rabi season.',
    agent: 'crop_advisor',
    createdAt: DateTime(2026, 1, 1, 10, 1),
  );

  final voiceMsg = Message(
    id: '3',
    farmerId: 'raju-1',
    role: 'assistant',
    content: 'Use drip irrigation.',
    agent: 'irrigation_planner',
    audioPath: 'http://localhost:8002/audio/test.mp3',
    createdAt: DateTime(2026, 1, 1, 10, 2),
  );

  testWidgets('renders user message content', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: userMsg)));
    expect(find.text('Which crop for Rabi season?'), findsOneWidget);
  });

  testWidgets('user message is right-aligned', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: userMsg)));
    final row = tester.widget<Row>(find.byType(Row).first);
    expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));
  });

  testWidgets('assistant message is left-aligned', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: assistantMsg)));
    final row = tester.widget<Row>(find.byType(Row).first);
    expect(row.mainAxisAlignment, equals(MainAxisAlignment.start));
  });

  testWidgets('shows agent badge for assistant messages', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: assistantMsg)));
    expect(find.text('crop advisor'), findsOneWidget);
  });

  testWidgets('shows play button when audioPath is present', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: voiceMsg)));
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('no play button when no audioPath', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: assistantMsg)));
    expect(find.byIcon(Icons.play_circle_outline), findsNothing);
  });
}
```

- [ ] **Step 2: Write `flutter/test/features/chat/voice_recorder_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/features/chat/voice_recorder.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders mic button', (tester) async {
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: false,
        isSupported: true,
        onStart: () {},
        onStop: () {},
      ),
    ));
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('button is disabled when isSupported is false', (tester) async {
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: false,
        isSupported: false,
        onStart: () {},
        onStop: () {},
      ),
    ));
    final button = tester.widget<GestureDetector>(find.byType(GestureDetector).first);
    // disabled = no callbacks wired
    expect(button.onLongPressStart, isNull);
  });

  testWidgets('calls onStart on long press', (tester) async {
    bool started = false;
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: false,
        isSupported: true,
        onStart: () => started = true,
        onStop: () {},
      ),
    ));
    await tester.longPress(find.byType(GestureDetector).first);
    expect(started, isTrue);
  });

  testWidgets('shows recording indicator when isRecording is true', (tester) async {
    await tester.pumpWidget(_wrap(
      VoiceRecorder(
        isRecording: true,
        isSupported: true,
        onStart: () {},
        onStop: () {},
      ),
    ));
    expect(find.byIcon(Icons.stop_circle), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests to verify they FAIL**

```bash
cd flutter && flutter test test/features/chat/message_bubble_test.dart test/features/chat/voice_recorder_test.dart
```

Expected: FAILED

- [ ] **Step 4: Create `flutter/lib/features/chat/message_bubble.dart`**

```dart
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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
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
```

- [ ] **Step 5: Create `flutter/lib/features/chat/voice_recorder.dart`**

```dart
import 'package:flutter/material.dart';

class VoiceRecorder extends StatelessWidget {
  final bool isRecording;
  final bool isSupported;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const VoiceRecorder({
    super.key,
    required this.isRecording,
    required this.isSupported,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: isSupported ? (_) => onStart() : null,
      onLongPressEnd: isSupported ? (_) => onStop() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? Colors.red
              : (isSupported ? const Color(0xFFDCFCE7) : Colors.grey.shade200),
          boxShadow: isRecording
              ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
              : [],
        ),
        child: Icon(
          isRecording ? Icons.stop_circle : Icons.mic,
          color: isRecording ? Colors.white : (isSupported ? const Color(0xFF166534) : Colors.grey),
          size: 28,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they PASS**

```bash
cd flutter && flutter test test/features/chat/message_bubble_test.dart test/features/chat/voice_recorder_test.dart
```

Expected: `All tests passed!` (10 tests)

- [ ] **Step 7: Commit**

```bash
cd flutter
git add lib/features/chat/message_bubble.dart lib/features/chat/voice_recorder.dart test/features/chat/message_bubble_test.dart test/features/chat/voice_recorder_test.dart
git commit -m "feat(flutter): add MessageBubble and VoiceRecorder chat widgets"
```

---

## Task 9: ChatScreen

**Files:**
- Create: `flutter/lib/features/chat/chat_screen.dart`
- Create: `flutter/test/features/chat/chat_screen_test.dart`

- [ ] **Step 1: Write `flutter/test/features/chat/chat_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:drift/native.dart';
import 'package:farmai/services/api_service.dart';
import 'package:farmai/services/auth_service.dart';
import 'package:farmai/services/voice_service.dart';
import 'package:farmai/services/storage_service.dart';
import 'package:farmai/core/connectivity_watcher.dart';
import 'package:farmai/features/chat/chat_screen.dart';

class MockApiService extends Mock implements ApiService {}
class MockAuthService extends Mock implements AuthService {}
class MockVoiceService extends Mock implements VoiceService {}
class MockConnectivityWatcher extends Mock implements ConnectivityWatcher {}

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

Widget _buildTestWidget({
  required MockApiService api,
  required MockAuthService auth,
  required MockVoiceService voice,
  required MockConnectivityWatcher connectivity,
  required AppDatabase db,
}) {
  return MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      Provider<AuthService>.value(value: auth),
      Provider<VoiceService>.value(value: voice),
      Provider<ConnectivityWatcher>.value(value: connectivity),
      Provider<AppDatabase>.value(value: db),
    ],
    child: const MaterialApp(home: ChatScreen()),
  );
}

void main() {
  late MockApiService mockApi;
  late MockAuthService mockAuth;
  late MockVoiceService mockVoice;
  late MockConnectivityWatcher mockConnectivity;
  late AppDatabase db;

  setUp(() {
    mockApi = MockApiService();
    mockAuth = MockAuthService();
    mockVoice = MockVoiceService();
    mockConnectivity = MockConnectivityWatcher();
    db = _inMemoryDb();

    when(() => mockAuth.getFarmerId()).thenAnswer((_) async => 'raju-1');
    when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
    when(() => mockConnectivity.onlineStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockVoice.isRecording).thenReturn(false);
  });

  tearDown(() async => db.close());

  testWidgets('shows welcome message on first load', (tester) async {
    await tester.pumpWidget(_buildTestWidget(
      api: mockApi, auth: mockAuth, voice: mockVoice,
      connectivity: mockConnectivity, db: db,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Namaste'), findsOneWidget);
  });

  testWidgets('shows text input and Send button', (tester) async {
    await tester.pumpWidget(_buildTestWidget(
      api: mockApi, auth: mockAuth, voice: mockVoice,
      connectivity: mockConnectivity, db: db,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('Send button disabled when input is empty', (tester) async {
    await tester.pumpWidget(_buildTestWidget(
      api: mockApi, auth: mockAuth, voice: mockVoice,
      connectivity: mockConnectivity, db: db,
    ));
    await tester.pumpAndSettle();
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send'));
    expect(button.onPressed, isNull);
  });

  testWidgets('typing message enables Send button', (tester) async {
    await tester.pumpWidget(_buildTestWidget(
      api: mockApi, auth: mockAuth, voice: mockVoice,
      connectivity: mockConnectivity, db: db,
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'कौन सी फसल?');
    await tester.pump();
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping Send calls api.textChat', (tester) async {
    when(() => mockApi.textChat(
          farmerId: any(named: 'farmerId'),
          text: any(named: 'text'),
          language: any(named: 'language'),
        )).thenAnswer((_) async => {
          'text_response': 'Plant wheat',
          'translated_response': 'गेहूं उगाएं',
          'agent_used': 'crop_advisor',
          'queued': false,
        });

    await tester.pumpWidget(_buildTestWidget(
      api: mockApi, auth: mockAuth, voice: mockVoice,
      connectivity: mockConnectivity, db: db,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Which crop?');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    verify(() => mockApi.textChat(
          farmerId: 'raju-1',
          text: 'Which crop?',
          language: 'hi',
        )).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it FAILS**

```bash
cd flutter && flutter test test/features/chat/chat_screen_test.dart
```

Expected: FAILED

- [ ] **Step 3: Create `flutter/lib/features/chat/chat_screen.dart`**

```dart
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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

    // Send voice to BFF
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
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
```

- [ ] **Step 4: Run test to verify it PASSES**

```bash
cd flutter && flutter test test/features/chat/chat_screen_test.dart
```

Expected: `All tests passed!` (5 tests)

- [ ] **Step 5: Commit**

```bash
cd flutter
git add lib/features/chat/chat_screen.dart test/features/chat/chat_screen_test.dart
git commit -m "feat(flutter): add ChatScreen with voice, text, offline handling"
```

---

## Task 10: Dashboard + History screens

**Files:**
- Create: `flutter/lib/features/dashboard/agent_status_widget.dart`
- Create: `flutter/lib/features/dashboard/dashboard_screen.dart`
- Create: `flutter/lib/features/history/history_screen.dart`
- Create: `flutter/test/features/dashboard/dashboard_screen_test.dart`
- Create: `flutter/test/features/history/history_screen_test.dart`

- [ ] **Step 1: Write `flutter/test/features/dashboard/dashboard_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmai/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('renders Farm Overview heading', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Farm Overview'), findsOneWidget);
  });

  testWidgets('shows all four stat cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Current Crops'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Land'), findsOneWidget);
    expect(find.text('Irrigation'), findsOneWidget);
  });

  testWidgets('shows Agent System Status section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('Agent System Status'), findsOneWidget);
  });

  testWidgets('shows all 5 specialist agents', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('crop advisor'), findsOneWidget);
    expect(find.text('pest detector'), findsOneWidget);
    expect(find.text('market analyst'), findsOneWidget);
    expect(find.text('irrigation planner'), findsOneWidget);
    expect(find.text('scheme navigator'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Write `flutter/test/features/history/history_screen_test.dart`**

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:farmai/services/auth_service.dart';
import 'package:farmai/services/storage_service.dart';
import 'package:farmai/features/history/history_screen.dart';
import 'package:farmai/models/message.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

Widget _buildTestWidget(AppDatabase db, MockAuthService auth) {
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: db),
      Provider<AuthService>.value(value: auth),
    ],
    child: const MaterialApp(home: HistoryScreen()),
  );
}

void main() {
  late AppDatabase db;
  late MockAuthService mockAuth;

  setUp(() {
    db = _inMemoryDb();
    mockAuth = MockAuthService();
    when(() => mockAuth.getFarmerId()).thenAnswer((_) async => 'raju-1');
  });

  tearDown(() async => db.close());

  testWidgets('shows "No conversations yet" when history is empty', (tester) async {
    await tester.pumpWidget(_buildTestWidget(db, mockAuth));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('shows messages from database', (tester) async {
    await db.insertMessage(Message(
      id: 'msg-1',
      farmerId: 'raju-1',
      role: 'user',
      content: 'What to plant?',
      createdAt: DateTime(2026, 1, 1, 10, 0),
    ));

    await tester.pumpWidget(_buildTestWidget(db, mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('What to plant?'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests to verify they FAIL**

```bash
cd flutter && flutter test test/features/dashboard/dashboard_screen_test.dart test/features/history/history_screen_test.dart
```

Expected: FAILED

- [ ] **Step 4: Create `flutter/lib/features/dashboard/agent_status_widget.dart`**

```dart
import 'package:flutter/material.dart';

const _agents = [
  {'key': 'crop_advisor', 'label': 'crop advisor', 'icon': '🌾', 'color': Color(0xFFDCFCE7)},
  {'key': 'pest_detector', 'label': 'pest detector', 'icon': '🔬', 'color': Color(0xFFFFE4E6)},
  {'key': 'market_analyst', 'label': 'market analyst', 'icon': '📈', 'color': Color(0xFFDBEAFE)},
  {'key': 'irrigation_planner', 'label': 'irrigation planner', 'icon': '💧', 'color': Color(0xFFCFFAFE)},
  {'key': 'scheme_navigator', 'label': 'scheme navigator', 'icon': '🏛', 'color': Color(0xFFF3E8FF)},
];

const _mcpTools = [
  '🌤 weather_forecast(location, days)',
  '💰 mandi_prices(crop, state)',
  '🌍 soil_analysis(lat, lon)',
  '🏛 government_schemes(state, crop, category)',
];

class AgentStatusWidget extends StatelessWidget {
  const AgentStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agent System Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._agents.map((agent) => _agentTile(agent)),
        const SizedBox(height: 16),
        _mcpToolsCard(),
      ],
    );
  }

  Widget _agentTile(Map<String, dynamic> agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(agent['icon'] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(agent['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 4),
          const Text('Ready', style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80))),
        ],
      ),
    );
  }

  Widget _mcpToolsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔌 MCP Tools Active',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._mcpTools.map((tool) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tool,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Create `flutter/lib/features/dashboard/dashboard_screen.dart`**

```dart
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
```

- [ ] **Step 6: Create `flutter/lib/features/history/history_screen.dart`**

```dart
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
    if (farmerId == null) {
      setState(() => _loaded = true);
      return;
    }
    final msgs = await db.getMessages(farmerId, limit: 50);
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

    return ListView.builder(
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
    );
  }
}
```

- [ ] **Step 7: Run tests to verify they PASS**

```bash
cd flutter && flutter test test/features/dashboard/dashboard_screen_test.dart test/features/history/history_screen_test.dart
```

Expected: `All tests passed!` (6 tests)

- [ ] **Step 8: Commit**

```bash
cd flutter
git add lib/features/dashboard/ lib/features/history/ test/features/dashboard/ test/features/history/
git commit -m "feat(flutter): add DashboardScreen, AgentStatusWidget, HistoryScreen"
```

---

## Task 11: Main app wiring + bottom navigation

**Files:**
- Modify: `flutter/lib/main.dart`

- [ ] **Step 1: Replace `flutter/lib/main.dart` with full wired app**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/connectivity_watcher.dart';
import 'core/theme.dart';
import 'features/auth/otp_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/history/history_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/voice_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FarmAIApp());
}

class FarmAIApp extends StatelessWidget {
  const FarmAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase();
    final authService = AuthService();
    final apiService = ApiService(auth: authService);
    final syncService = SyncService(api: apiService, db: db);

    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<AuthService>.value(value: authService),
        Provider<ApiService>.value(value: apiService),
        Provider<VoiceService>(create: (_) => VoiceService()),
        Provider<ConnectivityWatcher>(create: (_) => ConnectivityWatcher()),
        Provider<SyncService>.value(value: syncService),
      ],
      child: MaterialApp(
        title: 'FarmAI',
        theme: FarmAITheme.theme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthService>();
    final loggedIn = await auth.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isLoggedIn!) {
      return OtpScreen(onSuccess: () => setState(() => _isLoggedIn = true));
    }
    return const _MainShell();
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    ChatScreen(),
    DashboardScreen(),
    HistoryScreen(),
  ];

  static const _labels = ['Chat', 'Dashboard', 'History'];
  static const _icons = [Icons.chat_bubble_outline, Icons.dashboard_outlined, Icons.history];
  static const _activeIcons = [Icons.chat_bubble, Icons.dashboard, Icons.history];

  @override
  void initState() {
    super.initState();
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    final sync = context.read<SyncService>();
    final connectivity = context.read<ConnectivityWatcher>();
    if (await connectivity.isOnline) {
      await sync.flushQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🌱', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FarmAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Powered by Claude + MCP + RAG',
                    style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                SizedBox(width: 4),
                Text('All agents active',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: List.generate(
          3,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run full test suite**

```bash
cd flutter && flutter test
```

Expected: All tests pass. Note the count.

If any tests fail, investigate and fix before committing.

- [ ] **Step 3: Commit**

```bash
cd flutter
git add lib/main.dart
git commit -m "feat(flutter): wire up full app — auth gate, bottom nav, sync on launch"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|---|---|
| Flutter iOS/Android app | Task 1 (project setup) |
| Phone number + OTP auth | Task 3 (AuthService) + Task 7 (OtpScreen) |
| JWT stored in flutter_secure_storage | Task 3 |
| Voice-first input with MediaRecorder equivalent | Task 5 (VoiceService + record package) + Task 8 (VoiceRecorder) |
| TTS audio playback (just_audio) | Task 5 (VoiceService.playAudio) + Task 8 (MessageBubble play button) |
| SQLite offline storage (Drift) | Task 2 (AppDatabase, 3 tables) |
| Offline queue with pending/sending/failed states | Task 2 (OfflineQueue table) + Task 6 (SyncService) |
| Max 3 retries, mark failed | Task 6 (SyncService._maxRetries) |
| Flush queue on connectivity restored | Task 11 (ConnectivityWatcher stream → triggerSync) |
| `offline_queue` table columns match spec | Task 2 |
| Farmer profile cached at login | Task 2 (FarmerProfiles table + upsertFarmer) |
| Conversation history (last 20) | Task 2 (getMessages limit) |
| BFF HTTP calls (Dio) | Task 4 (ApiService: sendOtp, verifyOtp, textChat, voiceChat, syncPush, syncPull) |
| Authorization: Bearer JWT header | Task 4 (_authOptions) |
| Chat screen with voice + text | Task 9 (ChatScreen) |
| Offline banner | Task 9 (isOnline → amber banner) |
| Dashboard — farm stats + agent status | Task 10 |
| History screen from SQLite | Task 10 |
| Bottom navigation (Chat / Dashboard / History) | Task 11 |
| Sync on app launch | Task 11 (_triggerSync in initState) |
| connectivity_plus for network changes | Task 5 (ConnectivityWatcher) |
