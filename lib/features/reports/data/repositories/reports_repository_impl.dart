import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/reports/data/datasources/reports_data_source.dart';
import 'package:soplay/features/reports/domain/entities/report_payload.dart';
import 'package:soplay/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDataSource dataSource;
  const ReportsRepositoryImpl(this.dataSource);

  @override
  Future<Result<void>> submit(ReportPayload payload) async {
    try {
      await dataSource.submit(payload);
      return const Success(null);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final serverMessage =
          (e.response?.data as Map<String, dynamic>?)?['message'] as String?;
      switch (code) {
        case 400:
          return Failure(
            Exception(serverMessage ?? 'Sabab yoki turi noto\'g\'ri'),
          );
        case 403:
          return Failure(Exception(
            serverMessage ??
                'Yangi akkauntdan shikoyat yuborib bo\'lmaydi',
          ));
        case 409:
          return Failure(
            Exception('Bu obyektga shikoyatingiz allaqachon yuborilgan'),
          );
        case 429:
          return Failure(Exception(
            serverMessage ?? 'Juda ko\'p so\'rov, keyinroq urinib ko\'ring',
          ));
      }
      return Failure(
        Exception(serverMessage ?? e.message ?? 'Xatolik yuz berdi'),
      );
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
