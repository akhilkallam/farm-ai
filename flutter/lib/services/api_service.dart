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
