import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/data/datasources/home_data_source.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/domain/entities/view_all_paging_entity.dart';
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
      print('message: $message');
      return Failure(Exception(message));
    } catch (e) {
      print('message: ${e.toString()}');
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
      final data = await dataSource.loadViewAll( slug: slug, page: page, type: key);
      return Success(data);
    } on DioException catch (e) {
      final message =
          (e.response?.data as Map?)?['message'] ??
          e.message ??
          'Xatolik yuz berdi';
      print('message: $message');
      return Failure(Exception(message));
    } catch (e) {
      print('message: ${e.toString()}');
      return Failure(Exception(e.toString()));
    }
  }
}
