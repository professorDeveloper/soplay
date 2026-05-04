import 'episode_entity.dart';
import 'video_source_entity.dart';

class PlayerArgs {
  final String title;
  final String provider;
  final String? movieUrl;
  final String? type;
  final List<VideoSourceEntity> videoSources;
  final Map<String, String> headers;
  final List<EpisodeEntity> episodes;
  final int initialEpisodeIndex;
  final String? initialLang;

  const PlayerArgs({
    required this.title,
    required this.provider,
    required this.headers,
    this.movieUrl,
    this.type,
    this.videoSources = const [],
    this.episodes = const [],
    this.initialEpisodeIndex = 0,
    this.initialLang,
  });

  bool get isSerial => episodes.isNotEmpty;
}
