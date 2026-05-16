import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'dart_fetch.dart';
import 'extractor_cache.dart';
import 'extractor_remote.dart';
import 'js_log.dart';
import 'provider_registry.dart';

class JsRuntimeService {
  final ExtractorRemote remote;
  final ExtractorCache cache;
  final DartFetch dartFetch;
  final ProviderRegistry providers;

  HeadlessInAppWebView? _webView;
  InAppWebViewController? _controller;
  Future<void>? _ready;
  ExtractorManifest? _manifest;
  String? _activeExtractor;
  int? _activeVersion;

  static const String _runtimeName = '__runtime__';
  static const String _bootstrapHtml = '''
<!doctype html>
<html><head><meta charset="utf-8"></head>
<body><script>
  window.dartFetch = function(req) {
    return window.flutter_inappwebview.callHandler('dartFetch', req);
  };
  window.__sozoReady = true;
</script></body></html>
''';

  JsRuntimeService({
    required this.remote,
    required this.cache,
    required this.dartFetch,
    required this.providers,
  });

  Future<void> ensureReady() {
    return _ready ??= _boot().catchError((Object e) {
      _ready = null;
      JsLog.err('js', 'boot failed: $e');
      throw e;
    });
  }

  Future<bool> isClientCatalog(String provider) async {
    final p = await providers.getById(provider);
    return p?.scopesAll == true;
  }

  Future<bool> isJsResolveMedia(String provider) async {
    final p = await providers.getById(provider);
    return p?.scopesResolveMedia == true;
  }

  Future<Map<String, dynamic>?> tryGetHome(String provider) =>
      _callObject(provider, 'getHome', requireAll: true);

  Future<Map<String, dynamic>?> tryGetCategory(
    String provider,
    String slug,
    int page,
  ) =>
      _callObject(
        provider,
        'getCategory',
        requireAll: true,
        args: [slug, page],
      );

  Future<Map<String, dynamic>?> trySearch(
    String provider,
    String query,
    int page,
  ) =>
      _callObject(
        provider,
        'search',
        requireAll: true,
        args: [query, page],
      );

  Future<Map<String, dynamic>?> tryGetDetail(String provider, String url) =>
      _callObject(provider, 'getDetail', requireAll: true, args: [url]);

  Future<Map<String, dynamic>?> tryGetEpisodes(String provider, String url) =>
      _callObject(provider, 'getEpisodes', requireAll: true, args: [url]);

  Future<Map<String, dynamic>?> tryResolveMedia({
    required String provider,
    required String ref,
    String? lang,
  }) =>
      _callObject(
        provider,
        'resolveMedia',
        requireAll: false,
        args: [ref, {'lang': lang ?? 'sub'}],
      );

  Future<Map<String, dynamic>?> _callObject(
    String provider,
    String fn, {
    required bool requireAll,
    List<Object?> args = const [],
  }) async {
    final tag = 'js:$provider';
    final entity = await providers.getById(provider);
    if (entity == null) {
      JsLog.info(tag, 'skip $fn — provider not in registry');
      return null;
    }
    final eligible = requireAll ? entity.scopesAll : entity.scopesResolveMedia;
    if (!eligible) {
      JsLog.info(
        tag,
        'skip $fn — scope=${entity.extractor?.scope ?? "none"} mode=${entity.mode}',
      );
      return null;
    }
    final extractor = entity.extractor!;
    final sw = Stopwatch()..start();
    JsLog.req(tag, '$fn(${_summarizeArgs(args)})');
    try {
      await ensureReady();
      await _ensureExtractor(extractor.name, extractor.version);

      final result = await _controller!.callAsyncJavaScript(
        functionBody: r'''
          const __fn = (typeof Provider !== 'undefined') ? Provider[fnName] : null;
          if (typeof __fn !== 'function') {
            throw new Error('Provider.' + fnName + ' is not implemented');
          }
          const __r = await __fn.apply(Provider, fnArgs);
          return __r === undefined ? null : __r;
        ''',
        arguments: {
          'fnName': fn,
          'fnArgs': args,
        },
      );

      if (result == null) {
        JsLog.err(tag, '$fn returned null result');
        return null;
      }
      final error = result.error;
      if (error != null && error.isNotEmpty) {
        JsLog.err(tag, '$fn threw: $error');
        throw Exception(error);
      }
      final map = _coerceMap(result.value);
      JsLog.res(
        tag,
        fn,
        ms: sw.elapsedMilliseconds,
        status: map == null ? 0 : 200,
      );
      return map;
    } catch (e) {
      JsLog.err(tag, '$fn — $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _coerceMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value.cast<String, dynamic>();
    if (value is String) {
      if (value.isEmpty || value == 'null') return null;
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return null;
  }

  String _summarizeArgs(List<Object?> args) {
    if (args.isEmpty) return '';
    return args
        .map((a) {
          final s = a is String ? '"${_clip(a, 60)}"' : a.toString();
          return _clip(s, 80);
        })
        .join(', ');
  }

  String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  Future<void> _boot() async {
    final controllerCompleter = Completer<InAppWebViewController>();

    final webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri('about:blank')),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        mediaPlaybackRequiresUserGesture: true,
        clearCache: false,
        cacheEnabled: false,
        transparentBackground: true,
        thirdPartyCookiesEnabled: true,
      ),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'dartFetch',
          callback: (args) async {
            if (args.isEmpty) {
              return {'status': 0, 'data': null, 'headers': {}};
            }
            return await dartFetch.call(args.first);
          },
        );
        if (!controllerCompleter.isCompleted) {
          controllerCompleter.complete(controller);
        }
      },
      onConsoleMessage: (_, msg) {
        JsLog.info('js', 'console: ${msg.message}');
      },
    );

    await webView.run();
    _webView = webView;
    final controller = await controllerCompleter.future;
    _controller = controller;

    await controller.loadData(
      data: _bootstrapHtml,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://sozo.local/'),
    );
    await _waitForReady(controller);

    final manifest = await remote.fetchManifest();
    _manifest = manifest;
    await _ensureRuntime(manifest.runtime);
  }

  Future<void> _waitForReady(InAppWebViewController controller) async {
    for (var i = 0; i < 60; i++) {
      final flag = await controller.evaluateJavascript(
        source: 'window.__sozoReady === true',
      );
      if (flag == true) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('WebView JS context did not initialize');
  }

  Future<void> _ensureRuntime(ExtractorAsset asset) async {
    final wantedVersion = asset.version > 0 ? asset.version : 1;
    final cachedVersion = cache.readVersion(_runtimeName);
    String? code;
    if (cachedVersion == wantedVersion) {
      code = cache.readCode(_runtimeName, cachedVersion!);
    }
    if (code == null || code.isEmpty) {
      final fetched = await remote.fetchRuntime();
      code = fetched.code;
      final effective = wantedVersion > 0 ? wantedVersion : fetched.version;
      await cache.writeCode(
        name: _runtimeName,
        version: effective > 0 ? effective : 1,
        code: code,
      );
    }
    if (code.isEmpty) throw StateError('Runtime JS is empty');
    await _controller!.evaluateJavascript(source: code);
  }

  Future<void> _ensureExtractor(String name, int wantedVersion) async {
    final manifest = _manifest ??= await remote.fetchManifest();
    final entry = manifest.byName(name);
    final version = entry?.version ?? wantedVersion;
    if (_activeExtractor == name && _activeVersion == version) return;

    final cachedVersion = cache.readVersion(name);
    String? code;
    if (cachedVersion == version && version > 0) {
      code = cache.readCode(name, version);
    }
    if (code == null || code.isEmpty) {
      final fetched = await remote.fetchExtractor(name);
      code = fetched.code;
      final effective = version > 0 ? version : fetched.version;
      await cache.writeCode(
        name: name,
        version: effective > 0 ? effective : 1,
        code: code,
      );
    }
    if (code.isEmpty) throw StateError('Extractor "$name" JS is empty');
    final wrapped = '''
(function(){
  try { delete globalThis.Provider; } catch (e) {}
  $code
  if (typeof Provider !== 'undefined') {
    globalThis.Provider = Provider;
  }
})();
''';
    await _controller!.evaluateJavascript(source: wrapped);
    _activeExtractor = name;
    _activeVersion = version;
  }

  Future<void> dispose() async {
    try {
      await _webView?.dispose();
    } catch (e) {
      JsLog.err('js', 'dispose: $e');
    }
    _webView = null;
    _controller = null;
    _ready = null;
    _activeExtractor = null;
    _activeVersion = null;
  }
}
