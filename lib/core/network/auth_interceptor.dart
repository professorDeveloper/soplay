import 'package:dio/dio.dart';
import 'package:soplay/core/storage/hive_service.dart';

class AuthInterceptor extends Interceptor {
  final HiveService hiveService;
  final Dio dio;

  AuthInterceptor({required this.hiveService, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = hiveService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = hiveService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final response = await dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Authorization': null},
              extra: {'skipAuthInterceptor': true},
            ),
          );
          final data = response.data as Map<String, dynamic>;
          final newAccess = data['accessToken'] as String? ?? '';
          final newRefresh = data['refreshToken'] as String? ?? refreshToken;

          if (newAccess.isNotEmpty) {
            await hiveService.saveTokens(
              accessToken: newAccess,
              refreshToken: newRefresh,
            );
            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retryResponse = await dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          await hiveService.clearAuth();
        }
      }
    }
    handler.next(err);
  }
}
