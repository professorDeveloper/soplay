import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSource({required this.dio});

  Future<AuthModel> login(String email, String password) async {
    final response = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthModel> register(
    String email,
    String password,
    String username,
  ) async {
    final response = await dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'username': username},
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
