import 'package:soplay/features/home/domain/entities/home_section_entity.dart';

import 'movie_model.dart';

class HomeSectionModel extends HomeSectionEntity {
  HomeSectionModel({
    required super.key,
    required super.label,
    required super.items,
  });
  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      key: json['key'] as String,
      label: json['label'] as String,
      items: (json['items'] as List)
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
