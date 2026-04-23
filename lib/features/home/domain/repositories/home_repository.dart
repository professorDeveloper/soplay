import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/entities/home_data_entity.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';

abstract class HomeRepository {
  Future<Result<List<MovieEntity>>> loadBanner();

  Future<Result<HomeDataEntity>> loadHome();
}
