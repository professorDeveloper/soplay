import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSource({required this.dio});

  Future<AuthModel> login(String identifier, String password) async {
    final response = await dio.post(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
    );
    return AuthModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> requestRegisterOtp({
    required String email,
    required String username,
    required String password,
  }) async {
    await dio.post(
      '/auth/register',
      data: {'email': email, 'username': username, 'password': password},
    );
  }

  Future<void> resendRegisterOtp(String email) async {
    await dio.post(
      '/auth/register/resend',
      data: {'email': email},
    );
  }

  Future<AuthModel> verifyRegisterOtp({
    required String email,
    required String code,
  }) async {
    final response = await dio.post(
      '/auth/register/verify',
      data: {'email': email, 'otp': code},
    );
    return AuthModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> getProfile() async {
    final response = await dio.get('/auth/profile');
    final data = response.data as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userJson);
  }

  Future<Map<String, String>> refresh(String refreshToken) async {
    final response = await dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'accessToken': data['accessToken'] as String? ?? '',
      'refreshToken': data['refreshToken'] as String? ?? refreshToken,
    };
  }

  Future<void> logout() async {
    await dio.post('/auth/logout');
  }
}
