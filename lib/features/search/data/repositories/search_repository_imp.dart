import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/search/data/model/genre_model.dart';
import 'package:soplay/features/search/data/model/search_model.dart';
import 'package:soplay/features/search/domain/repositories/search_repository.dart';

import '../datasources/search_data_source.dart';

class SearchRepositoryImp extends SearchRepository {
  final SearchDataSource dataSource;

  SearchRepositoryImp({required this.dataSource});

  @override
  Future<Result<List<GenreModel>>> getGenres() async {
    try {
      final result = await dataSource.getGenres();
      return Success(result);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<SearchModel>> getMoviesByGenre(
    String genre, {
    int page = 1,
  }) async {
    try {
      final result = await dataSource.getMoviesByGenre(genre, page: page);
      return Success(result);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<SearchModel>> searchMovies(String query, {int page = 1}) async  {
    try {
      final result = await dataSource.searchMovies(query, page: page);
      return Success(result);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
