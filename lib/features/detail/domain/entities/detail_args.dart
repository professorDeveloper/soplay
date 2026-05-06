import 'package:soplay/features/home/domain/entities/movie.dart';

class DetailArgs {
  final String contentUrl;
  final MovieEntity? preview;
  final bool autoPlay;
  final int? resumeEpisodeIndex;
  final String? provider;

  const DetailArgs({
    required this.contentUrl,
    this.preview,
    this.autoPlay = false,
    this.resumeEpisodeIndex,
    this.provider,
  });
}
