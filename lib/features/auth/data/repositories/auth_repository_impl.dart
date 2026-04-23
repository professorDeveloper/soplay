import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final HiveService _hiveService;

  AuthRepositoryImpl(this._remoteDataSource, this._hiveService);

  @override
  Future<Result<AuthToken>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final model = await _remoteDataSource.register(email, password, username);
      await _hiveService.saveAuth(token: model.token, user: model.user);
      return Result(value: model);
    } on DioException catch (e) {
      final message =
          (e.response?.data as Map?)?['message'] ??
          e.message ??
          'Xatolik yuz berdi';
      return Result(error: Exception(message));
    } catch (e) {
      return Result(error: Exception(e.toString()));
    }
  }

  @override
  Future<Result<AuthToken>> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    await _hiveService.clearAuth();
  }
}
