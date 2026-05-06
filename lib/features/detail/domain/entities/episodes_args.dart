import 'episode_entity.dart';

class EpisodesArgs {
  final String title;
  final String contentUrl;
  final String provider;
  final String? thumbnail;
  final List<EpisodeEntity> episodes;
  final Map<String, String> headers;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  const EpisodesArgs({
    required this.title,
    required this.episodes,
    this.contentUrl = '',
    this.provider = '',
    this.thumbnail,
    this.headers = const {},
    this.page = 1,
    this.size = 100,
    this.total = 0,
    this.totalPages = 1,
  });
}
