import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/entities/home_data_entity.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/domain/entities/view_all_paging_entity.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';

abstract class HomeRepository {
  Future<Result<HomeDataEntity>> loadHome();

  Future<Result<List<GenreEntity>>> loadGenres();

  Future<Result<ViewAllPagingEntity>> loadViewAll({
    required String key,
    required String slug,
    int page = 1,
  });
}
