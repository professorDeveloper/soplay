import '../../../../core/error/result.dart';
import '../entities/genre_entity.dart';
import '../entities/search_entity.dart';
import '../repositories/search_repository.dart';

class GenreUseCase {
  final SearchRepository repository;

  GenreUseCase({required this.repository});

  Future<Result<List<GenreEntity>>> call() => repository.getGenres();

  Future<Result<SearchEntity>> callByGenre(String genre, {int page = 1}) =>
      repository.getMoviesByGenre(genre, page: page);
}
