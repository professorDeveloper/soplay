import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/reports/domain/entities/report_payload.dart';

abstract class ReportsRepository {
  Future<Result<void>> submit(ReportPayload payload);
}
