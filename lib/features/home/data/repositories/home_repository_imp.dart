import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/js/js_runtime_service.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/home/data/datasources/home_data_source.dart';
import 'package:soplay/features/home/data/models/home_data_model.dart';
import 'package:soplay/features/home/data/models/view_all_paging_model.dart';
import 'package:soplay/features/home/domain/entities/view_all_paging_entity.dart';
import 'package:soplay/features/home/domain/repositories/home_repository.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';

import '../../domain/entities/home_data_entity.dart';

class HomeRepositoryImp implements HomeRepository {
  final HomeDataSource dataSource;
  final JsRuntimeService? jsRuntime;
  final HiveService? hive;

  const HomeRepositoryImp(this.dataSource, {this.jsRuntime, this.hive});

  String? get _currentProvider {
    final id = hive?.getCurrentProvider();
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  Future<Result<HomeDataEntity>> loadHome() async {
    final js = jsRuntime;
    final provider = _currentProvider;
    if (js != null && provider != null) {
      try {
        final map = await js.tryGetHome(provider);
        if (map != null) return Success(HomeDataModel.fromJson(map));
      } catch (e) {
        return Failure(Exception(e.toString()));
      }
    }

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
    final js = jsRuntime;
    final provider = _currentProvider;
    if (js != null && provider != null && key == 'category') {
      try {
        final map = await js.tryGetCategory(provider, slug, page);
        if (map != null) return Success(ViewAllPagingModel.fromJson(map));
      } catch (e) {
        return Failure(Exception(e.toString()));
      }
    }

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
