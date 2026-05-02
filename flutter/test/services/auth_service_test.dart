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
