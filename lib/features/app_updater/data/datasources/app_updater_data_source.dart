import 'package:dio/dio.dart';
import 'package:soplay/features/app_updater/data/models/app_version_check_model.dart';

class AppUpdaterDataSource {
  final Dio dio;
  const AppUpdaterDataSource({required this.dio});

  Future<AppVersionCheckModel> check({
    required String platform,
    required int currentVersion,
  }) async {
    final res = await dio.get(
      '/app-version',
      queryParameters: {
        'platform': platform,
        'currentVersion': currentVersion,
      },
      options: Options(extra: const {'skipAuthInterceptor': true}),
    );
    final data = res.data;
    if (data is Map) {
      return AppVersionCheckModel.fromJson(data.cast<String, dynamic>());
    }
    throw Exception('Invalid app-version response');
  }
}
