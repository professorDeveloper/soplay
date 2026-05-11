import 'package:soplay/features/detail/data/models/subtitle_model.dart';
import 'package:soplay/features/detail/data/models/video_source_model.dart';
import 'package:soplay/features/detail/domain/entities/media_resolve_entity.dart';

class MediaResolveModel extends MediaResolveEntity {
  const MediaResolveModel({
    required super.videoUrl,
    required super.headers,
    super.type,
    super.videoSources,
    super.languagesAvailable,
    super.activeLang,
    super.subtitles,
    super.thumbnails,
  });

  factory MediaResolveModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String?;
    final sources = (json['videoSources'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(VideoSourceModel.fromJson)
        .toList(growable: false);
    final subs = (json['subtitles'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SubtitleModel.fromJson)
        .toList(growable: false);
    final thumbs = json['thumbnails'] as String?;
    return MediaResolveModel(
      videoUrl: json['videoUrl'] as String? ?? '',
      type: typeRaw == null || typeRaw.isEmpty ? null : typeRaw.toLowerCase(),
      headers: _parseHeaders(json['headers']),
      videoSources: sources,
      languagesAvailable: _parseLangs(json['languagesAvailable']),
      activeLang: _parseActiveLang(json['server']),
      subtitles: subs,
      thumbnails: thumbs == null || thumbs.isEmpty ? null : thumbs,
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
