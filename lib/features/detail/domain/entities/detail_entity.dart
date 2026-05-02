import 'cast_entity.dart';
import 'screenshot_entity.dart';
import 'related_entity.dart';

class DetailEntity {
  final String provider;
  final String contentId;
  final String contentUrl;
  final String title;
  final String description;
  final String? thumbnail;
  final int? year;
  final String? duration;
  final String? country;
  final String? director;
  final List<String> genres;
  final List<CastEntity> cast;
  final int likes;
  final int dislikes;
  final bool isSerial;
  final List<ScreenshotEntity> screenshots;
  final List<RelatedEntity> related;

  const DetailEntity({
    required this.provider,
    required this.contentId,
    required this.contentUrl,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.year,
    required this.duration,
    required this.country,
    required this.director,
    required this.genres,
    required this.cast,
    required this.likes,
    required this.dislikes,
    required this.isSerial,
    required this.screenshots,
    required this.related,
  });
}
