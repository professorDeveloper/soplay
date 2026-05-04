import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';

class FavoriteModel extends FavoriteEntity {
  const FavoriteModel({
    required super.provider,
    required super.contentUrl,
    required super.title,
    required super.thumbnail,
    super.description,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
    provider: json['provider'] as String? ?? '',
    contentUrl: json['contentUrl'] as String? ?? '',
    title: json['title'] as String? ?? '',
    thumbnail: json['thumbnail'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}
