import 'package:soplay/features/home/domain/entities/movie.dart';

class DetailArgs {
  final String contentUrl;
  final MovieEntity? preview;

  const DetailArgs({required this.contentUrl, this.preview});
}
