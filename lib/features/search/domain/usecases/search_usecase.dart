import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/search/domain/entities/search_entity.dart';

import '../repositories/search_repository.dart';

class SearchUseCase {
  final SearchRepository repository;

  SearchUseCase({required this.repository});

  Future<Result<SearchEntity>> call(String query, {int page = 1}) =>
      repository.searchMovies(query, page: page);
}
