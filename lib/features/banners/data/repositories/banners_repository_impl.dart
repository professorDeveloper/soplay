import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/banners/data/datasources/banners_data_source.dart';
import 'package:soplay/features/banners/domain/entities/banner_item.dart';
import 'package:soplay/features/banners/domain/repositories/banners_repository.dart';

class BannersRepositoryImpl implements BannersRepository {
  final BannersDataSource dataSource;
  const BannersRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<BannerItem>>> list(String placement) async {
    try {
      final items = await dataSource.list(placement);
      return Success(items);
    } on DioException catch (e) {
      final raw = (e.response?.data as Map<String, dynamic>?)?['message']
              as String? ??
          e.message ??
          'Xatolik yuz berdi';
      return Failure(Exception(raw));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<void> trackView(String id) async {
    try {
      await dataSource.view(id);
    } catch (_) {}
  }

  @override
  Future<void> trackClick(String id) async {
    try {
      await dataSource.click(id);
    } catch (_) {}
  }
}
