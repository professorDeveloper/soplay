import 'package:soplay/features/detail/domain/entities/playback_entity.dart';
import 'episode_model.dart';
import 'video_source_model.dart';

class PlaybackModel extends PlaybackEntity {
  const PlaybackModel({
    required super.provider,
    required super.contentUrl,
    required super.isSerial,
    required super.episodes,
    required super.videoSources,
    required super.playerSrc,
    required super.headers,
    super.type,
    super.page,
    super.size,
    super.total,
    super.totalPages,
    super.sort,
  });

  factory PlaybackModel.fromJson(Map<String, dynamic> json) {
    final episodes = (json['episodes'] as List? ?? [])
        .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final videoSources = (json['videoSources'] as List? ?? [])
        .map((e) => VideoSourceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final src = json['playerSrc'] as String?;
    final typeRaw = json['type'] as String?;

    return PlaybackModel(
      provider: json['provider'] as String? ?? '',
      contentUrl: json['contentUrl'] as String? ?? '',
      isSerial: json['isSerial'] as bool? ?? false,
      episodes: episodes,
      videoSources: videoSources,
      playerSrc: src == null || src.isEmpty ? null : src,
      type: typeRaw == null || typeRaw.isEmpty ? null : typeRaw.toLowerCase(),
      headers: _parseHeaders(json['headers']),
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 100,
      total: (json['total'] as num?)?.toInt() ?? episodes.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      sort: (json['sort'] as String?)?.toLowerCase() ?? 'asc',
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
}
