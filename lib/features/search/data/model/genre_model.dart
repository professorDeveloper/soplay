import '../../domain/entities/genre_entity.dart';

class GenreModel extends GenreEntity {
  GenreModel({
    required super.provider,
    required super.slug,
    required super.url,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) => GenreModel(
    provider: json['provider'],
    slug: json['slug'],
    url: json['url'],
  );

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'slug': slug,
    'url': url,
  };
}
