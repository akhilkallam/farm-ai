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
