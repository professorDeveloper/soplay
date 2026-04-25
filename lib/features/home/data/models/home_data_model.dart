import 'package:soplay/features/home/domain/entities/home_data_entity.dart';

import 'home_section_model.dart';
import 'movie_model.dart';

class HomeDataModel extends HomeDataEntity {
  HomeDataModel({
    required super.provider,
    required super.banner,
    required super.sections,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      provider: json['provider'] as String? ?? '',
      banner: (json['banner'] as List? ?? [])
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((e) => HomeSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

