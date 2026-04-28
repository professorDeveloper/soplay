import 'package:dio/dio.dart';
import 'package:soplay/features/home/domain/entities/view_all_paging_entity.dart';

import '../models/home_data_model.dart';
import '../models/movie_model.dart';
import '../models/view_all_paging_model.dart';

class HomeDataSource {
  final Dio dio;

  const HomeDataSource({required this.dio});

  Future<HomeDataModel> loadHome() async {
    final results = await dio.get('/contents/home');
    return HomeDataModel.fromJson((results).data as Map<String, dynamic>);
  }

  Future<ViewAllPagingModel> loadViewAll({
    required String type,
    required String slug,
    required int page,
  }) async {
    final result;
    if (slug.isEmpty) {
      result = await dio.get(
        "/contents/$type",
        queryParameters: {"page": page},
      );
    } else {
      result = await dio.get(
        "/contents/$type/$slug",
        queryParameters: {"page": page},
      );
    }

    return ViewAllPagingModel.fromJson((result).data as Map<String, dynamic>);
  }
}
