import 'package:soplay/features/detail/domain/entities/episode_entity.dart';

class EpisodeModel extends EpisodeEntity {
  const EpisodeModel({
    required super.episode,
    required super.label,
    required super.mediaRef,
    super.availableLangs,
    super.hasSub,
    super.hasDub,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) => EpisodeModel(
        episode: (json['episode'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        mediaRef: json['mediaRef'] as String? ?? '',
        availableLangs: _parseLangs(json['availableLangs']),
        hasSub: json['hasSub'] as bool?,
        hasDub: json['hasDub'] as bool?,
      );

  static List<String> _parseLangs(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((e) => e.toLowerCase())
        .toList(growable: false);
  }
}
