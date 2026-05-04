import 'episode_entity.dart';
import 'video_source_entity.dart';

class PlaybackEntity {
  final String provider;
  final String contentUrl;
  final bool isSerial;
  final List<EpisodeEntity> episodes;
  final List<VideoSourceEntity> videoSources;
  final String? playerSrc;
  final Map<String, String> headers;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  const PlaybackEntity({
    required this.provider,
    required this.contentUrl,
    required this.isSerial,
    required this.episodes,
    required this.videoSources,
    required this.playerSrc,
    required this.headers,
    this.page = 1,
    this.size = 100,
    this.total = 0,
    this.totalPages = 1,
  });
}
