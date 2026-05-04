import 'package:soplay/features/detail/domain/entities/detail_entity.dart';
import 'cast_model.dart';
import 'related_model.dart';
import 'screenshot_model.dart';

class DetailModel extends DetailEntity {
  const DetailModel({
    required super.provider,
    required super.contentId,
    required super.contentUrl,
    required super.title,
    required super.description,
    required super.thumbnail,
    required super.year,
    required super.duration,
    required super.country,
    required super.director,
    required super.genres,
    required super.cast,
    required super.likes,
    required super.dislikes,
    required super.isSerial,
    required super.isFavorited,
    required super.screenshots,
    required super.related,
  });

  factory DetailModel.fromJson(Map<String, dynamic> json) {
    final castList = (json['cast'] as List? ?? [])
        .map((e) => CastModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final screenshotList = (json['screenshots'] as List? ?? [])
        .map((e) => ScreenshotModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final relatedList = (json['related'] as List? ?? [])
        .map((e) => RelatedModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final genreList = (json['genres'] as List? ?? [])
        .map((e) => e?.toString() ?? '')
        .where((g) => g.isNotEmpty)
        .toList();

    return DetailModel(
      provider: json['provider'] as String? ?? '',
      contentId: json['contentId'] as String? ?? '',
      contentUrl: json['contentUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      year: (json['year'] as num?)?.toInt(),
      duration: _nonEmpty(json['duration'] as String?),
      country: _nonEmpty(json['country'] as String?),
      director: _nonEmpty(json['director'] as String?),
      genres: genreList,
      cast: castList,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      isSerial: json['isSerial'] as bool? ?? false,
      isFavorited: _nullableBool(json['isFavorited']),
      screenshots: screenshotList,
      related: relatedList,
    );
  }

  static bool? _nullableBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
