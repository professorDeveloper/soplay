import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/data/datasources/home_data_source.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/domain/repositories/home_repository.dart';

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
      final message =
          (e.response?.data as Map?)?['message'] ??
          e.message ??
          'Xatolik yuz berdi';
      return Failure(Exception(message));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<MovieEntity>>> loadCategory(String category) {
    return _loadContent(
      () async =>
          List<MovieEntity>.from(await dataSource.loadCategory(category)),
    );
  }

  @override
  Future<Result<List<MovieEntity>>> loadGenre(String genre) {
    return _loadContent(
      () async => List<MovieEntity>.from(await dataSource.loadGenre(genre)),
    );
  }

  Future<Result<List<MovieEntity>>> _loadContent(
    Future<List<MovieEntity>> Function() request,
  ) async {
    try {
      final data = await request();
      return Success(data);
    } on DioException catch (e) {
      final message =
          (e.response?.data as Map?)?['message'] ??
          e.message ??
          'Xatolik yuz berdi';
      return Failure(Exception(message));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
