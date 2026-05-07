import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:soplay/core/router/app_router.dart';

class NoInternetInterceptor extends Interceptor {
  static int _lastRedirectMs = 0;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_looksOffline(err)) {
      _goNoInternet();
    }
    handler.next(err);
  }

  bool _looksOffline(DioException err) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    final error = err.error;
    return error is SocketException;
  }

  void _goNoInternet() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRedirectMs < 1200) return;
    _lastRedirectMs = now;

    final path = AppRouter.router.routeInformationProvider.value.uri.path;
    if (path == '/no-internet' || path == '/downloads') return;

    scheduleMicrotask(() {
      AppRouter.router.go('/no-internet');
    });
  }
}
