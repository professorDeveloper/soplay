import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:soplay/core/storage/hive_service.dart';

class AuthInterceptor extends Interceptor {
  static const _skipKey = 'skipAuthInterceptor';
  static const _retriedKey = 'authRetried';

  final HiveService hiveService;
  final Dio dio;
  final VoidCallback? onSessionExpired;

  Future<String?>? _refreshFuture;

  AuthInterceptor({
    required this.hiveService,
    required this.dio,
    this.onSessionExpired,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[_skipKey] == true) {
      handler.next(options);
      return;
    }
    final token = hiveService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isRefreshCall = request.path.contains('/auth/refresh');
    final alreadyRetried = request.extra[_retriedKey] == true;
    final isSkipped = request.extra[_skipKey] == true;

    if (err.response?.statusCode != 401 ||
        isRefreshCall ||
        alreadyRetried ||
        isSkipped) {
      handler.next(err);
      return;
    }

    final refreshToken = hiveService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      handler.next(err);
      return;
    }

    final newAccess = await _refresh(refreshToken);
    if (newAccess == null) {
      await _expireSession();
      handler.next(err);
      return;
    }

    request.headers['Authorization'] = 'Bearer $newAccess';
    request.extra[_retriedKey] = true;

    try {
      final retryResponse = await dio.fetch(request);
      handler.resolve(retryResponse);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refresh(String refreshToken) {
    _refreshFuture ??= _performRefresh(refreshToken).whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<String?> _performRefresh(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {_skipKey: true}),
      );
      final data = response.data as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String? ?? '';
      final newRefresh = data['refreshToken'] as String? ?? refreshToken;
      if (newAccess.isEmpty) return null;
      await hiveService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return newAccess;
    } catch (_) {
      return null;
    }
  }

  Future<void> _expireSession() async {
    await hiveService.clearAuth();
    onSessionExpired?.call();
  }
}
