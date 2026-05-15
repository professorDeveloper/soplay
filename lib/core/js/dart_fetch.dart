import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'js_log.dart';

class DartFetch {
  final Dio _dio;

  DartFetch._(this._dio);

  factory DartFetch.create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        followRedirects: true,
        maxRedirects: 10,
        validateStatus: (_) => true,
        responseType: ResponseType.plain,
      ),
    )..interceptors.add(CookieManager(CookieJar()));
    return DartFetch._(dio);
  }

  Future<Map<String, dynamic>> call(dynamic raw) async {
    final req = _coerceRequest(raw);
    if (req == null) {
      return const {'status': 0, 'data': null, 'headers': {}};
    }
    final sw = Stopwatch()..start();
    JsLog.req('fetch', '${req.method} ${_shortUrl(req.url)}');
    try {
      final response = await _dio.request<String>(
        req.url,
        data: req.body,
        options: Options(
          method: req.method,
          headers: req.headers,
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (_) => true,
        ),
      );
      final headers = <String, String>{};
      response.headers.forEach((k, v) => headers[k] = v.join(','));
      final status = response.statusCode ?? 0;
      JsLog.res(
        'fetch',
        '${req.method} ${_shortUrl(req.url)}',
        status: status,
        ms: sw.elapsedMilliseconds,
      );
      return {
        'status': status,
        'data': _decodeBody(response.data, headers['content-type']),
        'headers': headers,
      };
    } catch (e) {
      JsLog.err('fetch', '${req.method} ${_shortUrl(req.url)} — $e');
      return const {'status': 0, 'data': null, 'headers': {}};
    }
  }

  String _shortUrl(String url) {
    if (url.length <= 90) return url;
    return '${url.substring(0, 80)}…';
  }

  _Request? _coerceRequest(dynamic raw) {
    if (raw is! Map) return null;
    final url = raw['url'] as String?;
    if (url == null || url.isEmpty) return null;
    final method = (raw['method'] as String? ?? 'GET').toUpperCase();
    final headers = <String, String>{};
    final rawHeaders = raw['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) {
        if (k is String && v != null) headers[k] = v.toString();
      });
    }
    final body = raw['body'];
    return _Request(
      method: method,
      url: url,
      headers: headers,
      body: body,
    );
  }

  dynamic _decodeBody(String? data, String? contentType) {
    if (data == null || data.isEmpty) return data;
    if (contentType != null && contentType.toLowerCase().contains('application/json')) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }
}

class _Request {
  final String method;
  final String url;
  final Map<String, String> headers;
  final dynamic body;

  const _Request({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
  });
}
