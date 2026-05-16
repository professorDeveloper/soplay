import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/app_updater/data/datasources/app_updater_data_source.dart';
import 'package:soplay/features/app_updater/domain/entities/app_version_check.dart';
import 'package:soplay/features/app_updater/domain/repositories/app_updater_repository.dart';

class AppUpdaterRepositoryImpl implements AppUpdaterRepository {
  final AppUpdaterDataSource dataSource;
  const AppUpdaterRepositoryImpl(this.dataSource);

  @override
  Future<Result<AppVersionCheck>> check({
    required String platform,
    required int currentVersion,
  }) async {
    try {
      final result = await dataSource.check(
        platform: platform,
        currentVersion: currentVersion,
      );
      return Success(result);
    } on DioException catch (e) {
      final raw = (e.response?.data as Map<String, dynamic>?)?['message']
              as String? ??
          e.message ??
          'Xatolik';
      return Failure(Exception(raw));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
