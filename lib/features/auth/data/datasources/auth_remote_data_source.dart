import 'package:dio/dio.dart';
import 'package:soplay/core/network/dio_client.dart';
import '../models/auth_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSource({required this.dio});

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

  Future<AuthModel> login(String email, String password) async {
    final response = await dio.post(
      "/auth/login",
      data: {'email': email, 'password': password},
    );
    return AuthModel.fromJson(response.data as Map<String, dynamic>);
  }
}
