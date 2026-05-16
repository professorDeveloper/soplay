import 'package:dio/dio.dart';
import 'package:soplay/features/reports/domain/entities/report_payload.dart';

class ReportsDataSource {
  final Dio dio;
  const ReportsDataSource({required this.dio});

  Future<void> submit(ReportPayload payload) async {
    final body = <String, dynamic>{
      'targetType': payload.targetType,
      'reason': payload.reason,
    };
    if (payload.targetId != null && payload.targetId!.isNotEmpty) {
      body['targetId'] = payload.targetId;
    }
    if (payload.provider != null && payload.provider!.isNotEmpty) {
      body['provider'] = payload.provider;
    }
    if (payload.contentUrl != null && payload.contentUrl!.isNotEmpty) {
      body['contentUrl'] = payload.contentUrl;
    }
    if (payload.message != null && payload.message!.isNotEmpty) {
      body['message'] = payload.message;
    }
    await dio.post('/reports', data: body);
  }
}
