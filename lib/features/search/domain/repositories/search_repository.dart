import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';
import 'package:soplay/features/search/domain/entities/search_entity.dart';

abstract class SearchRepository {
  Future<Result<List<GenreEntity>>> getGenres();

  Future<Result<SearchEntity>> getMoviesByGenre(String genre, {int page = 1});

  Future<Result<SearchEntity>> searchMovies(String query, {int page = 1});
}
