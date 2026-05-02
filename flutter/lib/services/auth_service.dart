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
