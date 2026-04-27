import 'package:soplay/features/home/domain/entities/home_data_entity.dart';

import 'content_filter_model.dart';
import 'home_section_model.dart';
import 'movie_model.dart';

class HomeDataModel extends HomeDataEntity {
  HomeDataModel({
    required super.provider,
    required super.banner,
    required super.sections,
    required super.categories,
    required super.genres,
  });

  factory HomeDataModel.fromJson(
    Map<String, dynamic> json, {
    List<dynamic> categories = const [],
    List<dynamic> genres = const [],
  }) {
    return HomeDataModel(
      provider: json['provider'] as String? ?? '',
      banner: (json['banner'] as List? ?? [])
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((e) => HomeSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: categories
          .map((e) => ContentFilterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      genres: genres
          .map((e) => ContentFilterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
