import 'package:soplay/features/home/domain/entities/movie.dart';

class MovieModel extends MovieEntity {
  MovieModel({
    required super.externalId,
    required super.title,
    required super.slug,
    required super.url,
    required super.thumbnail,
    required super.provider,
    required super.year,
    required super.rating,
    required super.qualities,
    required super.category,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      externalId: json['externalId'],
      title: json['title'],
      slug: json['slug'],
      url: json['url'],
      provider: json['provider'],
      thumbnail: json['thumbnail'],
      year: json['year'],
      rating: json['rating'],
      qualities: List<String>.from(json['qualities']),
      category: json['category'],
    );
  }
}
