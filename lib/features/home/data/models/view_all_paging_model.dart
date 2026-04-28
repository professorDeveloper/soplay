import 'package:soplay/features/home/data/models/movie_model.dart';

import '../../domain/entities/view_all_paging_entity.dart';

class ViewAllPagingModel extends ViewAllPagingEntity {
  ViewAllPagingModel({
    required super.page,
    required super.totalPages,
    required super.provider,
    required super.items,
  });

  factory ViewAllPagingModel.fromJson(Map<String, dynamic> json) {
    return ViewAllPagingModel(
      page: json['page'],
      totalPages: json['totalPages'],
      provider: json['provider'],
      items: (json['items'] as List)
          .map((e) => MovieModel.fromJson(e))
          .toList(),
    );
  }
}
