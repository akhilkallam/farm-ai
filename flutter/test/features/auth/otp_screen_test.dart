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
