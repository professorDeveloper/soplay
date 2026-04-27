import 'package:dio/dio.dart';

import '../models/home_data_model.dart';
import '../models/movie_model.dart';

class HomeDataSource {
  final Dio dio;

  const HomeDataSource({required this.dio});

  Future<HomeDataModel> loadHome() async {
    final results = await Future.wait([
      dio.get('/contents/home'),
      _loadItems('/contents/categories'),
      _loadItems('/contents/genres'),
    ]);

    return HomeDataModel.fromJson(
      (results[0] as Response).data as Map<String, dynamic>,
      categories: results[1] as List<dynamic>,
      genres: results[2] as List<dynamic>,
    );
  }

  Future<List<dynamic>> _loadItems(String path) async {
    try {
      final response = await dio.get(path);
      return (response.data as Map<String, dynamic>)['items'] as List? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<MovieModel>> loadCategory(String category, {int page = 1}) async {
    return _loadContent('/contents/category/$category', page: page);
  }

  Future<List<MovieModel>> loadGenre(String genre, {int page = 1}) async {
    return _loadContent('/contents/genre/$genre', page: page);
  }

  Future<List<MovieModel>> _loadContent(
    String path, {
    required int page,
  }) async {
    final response = await dio.get(path, queryParameters: {'page': page});
    final items =
        (response.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items
        .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
