import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  static const _tag = '[HTTP]';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_startedAt'] = DateTime.now();
    final query = options.queryParameters.isEmpty
        ? ''
        : '?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    debugPrint('$_tag → ${options.method} ${options.path}$query');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final ms = _elapsed(response.requestOptions);
    debugPrint(
      '$_tag ← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.path} (${ms}ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ms = _elapsed(err.requestOptions);
    final code = err.response?.statusCode ?? '-';
    debugPrint(
      '$_tag ✗ $code ${err.requestOptions.method} '
      '${err.requestOptions.path} (${ms}ms) — ${err.message}',
    );
    handler.next(err);
  }

  int _elapsed(RequestOptions options) {
    final started = options.extra['_startedAt'];
    if (started is DateTime) {
      return DateTime.now().difference(started).inMilliseconds;
    }
    return -1;
  }
}
