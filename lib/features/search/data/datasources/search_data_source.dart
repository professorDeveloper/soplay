import 'package:dio/dio.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';

import '../model/search_model.dart';

class SearchDataSource {
  final Dio dio;

  SearchDataSource({required this.dio});

  Future<SearchModel> searchMovies(String query, {int page = 1}) async {
    var response = await dio.get('/search', queryParameters: {'query': query});
    return SearchModel.fromJson(response.data);
  }
}
