import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/data/datasources/home_data_source.dart';
import 'package:soplay/features/home/domain/entities/view_all_paging_entity.dart';
import 'package:soplay/features/home/domain/repositories/home_repository.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';

import '../../domain/entities/home_data_entity.dart';

class HomeRepositoryImp implements HomeRepository {
  final HomeDataSource dataSource;

  const HomeRepositoryImp(this.dataSource);

  @override
  Future<Result<HomeDataEntity>> loadHome() async {
    try {
      final data = await dataSource.loadHome();
      return Success(data);
    } on DioException catch (e) {
      final raw = e.response?.data;
      final message =
          (raw is Map ? raw['message'] : null) ??
          e.message ??
          'Xatolik yuz berdi';
      return Failure(Exception(message.toString()));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<ViewAllPagingEntity>> loadViewAll({
    required String key,
    required String slug,
    int page = 1,
  }) async {
    try {
      final data = await dataSource.loadViewAll(
        slug: slug,
        page: page,
        type: key,
      );
      return Success(data);
    } on DioException catch (e) {
      final raw = e.response?.data;
      final message =
          (raw is Map ? raw['message'] : null) ??
          e.message ??
          'Xatolik yuz berdi';
      return Failure(Exception(message.toString()));
    } catch (e) {
      print('message: ${e.toString()}');
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<GenreEntity>>> loadGenres() async {
    try {
      final data = await dataSource.loadGenres();
      return Success(data);
    } catch (e) {
      print("Message:${e.toString()}");
      return Failure(Exception(e.toString()));
    }
  }
}
