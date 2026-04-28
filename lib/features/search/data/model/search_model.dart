import 'package:soplay/features/home/data/models/movie_model.dart';

import '../../domain/entities/search_entity.dart';

class SearchModel extends SearchEntity {
  SearchModel({required super.provider, required super.items,
    required super.page, required super.totalPages
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) {
    return SearchModel(
      page: json['page'],
      totalPages: json['totalPages'],
      provider: json['provider'],
      items: (json['items'] as List)
          .map((e) => MovieModel.fromJson(e))
          .toList(),
    );
  }
}
