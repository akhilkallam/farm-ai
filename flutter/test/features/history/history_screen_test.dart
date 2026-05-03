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
