import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/entities/home_data_entity.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';

abstract class HomeRepository {
  Future<Result<HomeDataEntity>> loadHome();

  Future<Result<List<MovieEntity>>> loadCategory(String category);

  Future<Result<List<MovieEntity>>> loadGenre(String genre);
}
