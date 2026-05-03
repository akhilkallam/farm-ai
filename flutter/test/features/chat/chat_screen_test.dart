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
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verify(() => mockApi.textChat(
          farmerId: 'raju-1',
          text: 'Which crop?',
          language: 'hi',
        )).called(1);
  });
}
