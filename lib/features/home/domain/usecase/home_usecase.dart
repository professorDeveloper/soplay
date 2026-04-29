import 'package:soplay/features/search/domain/entities/genre_entity.dart';

import '../../../../core/error/result.dart';
import '../entities/home_data_entity.dart';
import '../entities/movie.dart';
import '../repositories/home_repository.dart';

class HomeUseCase {
  final HomeRepository homeRepository;

  const HomeUseCase(this.homeRepository);

  Future<Result<HomeDataEntity>> call() => homeRepository.loadHome();

  Future<Result<List<GenreEntity>>> callGenres() => homeRepository.loadGenres();
}
