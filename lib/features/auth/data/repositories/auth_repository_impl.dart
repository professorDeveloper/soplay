import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/data/models/user_model.dart';
import 'package:soplay/features/auth/domain/entities/auth_token.dart';
import 'package:soplay/features/auth/domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final HiveService _hiveService;

  AuthRepositoryImpl(this._remoteDataSource, this._hiveService);

  @override
  Future<Result<AuthToken>> login(String identifier, String password) async {
    try {
      final model = await _remoteDataSource.login(identifier, password);
      if (model.accessToken.isEmpty) {
        return Failure(Exception('Access token topilmadi'));
      }
      await _hiveService.saveAuth(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
        user: model.user as UserModel,
      );
      return Success(model);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> requestRegisterOtp({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      await _remoteDataSource.requestRegisterOtp(
        email: email,
        username: username,
        password: password,
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> resendRegisterOtp(String email) async {
    try {
      await _remoteDataSource.resendRegisterOtp(email);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<AuthToken>> verifyRegisterOtp({
    required String email,
    required String code,
  }) async {
    try {
      final model =
          await _remoteDataSource.verifyRegisterOtp(email: email, code: code);
      if (model.accessToken.isEmpty) {
        return Failure(Exception('Access token topilmadi'));
      }
      await _hiveService.saveAuth(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
        user: model.user as UserModel,
      );
      return Success(model);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity>> getProfile() async {
    try {
      final user = await _remoteDataSource.getProfile();
      await _hiveService.saveUser(user);
      return Success(user);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } on DioException {
      await _hiveService.clearAuth();
      return;
    }
    await _hiveService.clearAuth();
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return e.message ?? 'Xatolik yuz berdi';
  }
}
