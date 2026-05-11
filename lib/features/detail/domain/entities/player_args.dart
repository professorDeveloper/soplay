import 'episode_entity.dart';
import 'video_source_entity.dart';

class PlayerArgs {
  final String title;
  final String provider;
  final String? contentUrl;
  final String? thumbnail;
  final String? movieUrl;
  final String? type;
  final List<VideoSourceEntity> videoSources;
  final Map<String, String> headers;
  final List<EpisodeEntity> episodes;
  final int initialEpisodeIndex;
  final String? initialLang;
  final Duration resumePosition;
  final bool showDownloadAction;
  final String? thumbnails;

  const PlayerArgs({
    required this.title,
    required this.provider,
    required this.headers,
    this.contentUrl,
    this.thumbnail,
    this.movieUrl,
    this.type,
    this.videoSources = const [],
    this.episodes = const [],
    this.initialEpisodeIndex = 0,
    this.initialLang,
    this.resumePosition = Duration.zero,
    this.showDownloadAction = true,
    this.thumbnails,
  });

  bool get isSerial => episodes.isNotEmpty;
}
