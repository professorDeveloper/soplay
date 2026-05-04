import 'package:soplay/features/detail/domain/entities/media_resolve_entity.dart';

class MediaResolveModel extends MediaResolveEntity {
  const MediaResolveModel({
    required super.videoUrl,
    required super.headers,
    super.languagesAvailable,
    super.activeLang,
  });

  factory MediaResolveModel.fromJson(Map<String, dynamic> json) {
    return MediaResolveModel(
      videoUrl: json['videoUrl'] as String? ?? '',
      headers: _parseHeaders(json['headers']),
      languagesAvailable: _parseLangs(json['languagesAvailable']),
      activeLang: _parseActiveLang(json['server']),
    );
  }

  static Map<String, String> _parseHeaders(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (k is String && v != null) out[k] = v.toString();
    });
    return out;
  }

  static List<String> _parseLangs(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((e) => e.toLowerCase())
        .toList(growable: false);
  }

  static String? _parseActiveLang(dynamic server) {
    if (server is! Map) return null;
    final lang = server['lang'];
    return lang is String ? lang.toLowerCase() : null;
  }
}
