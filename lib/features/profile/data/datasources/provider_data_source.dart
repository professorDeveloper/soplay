import 'package:dio/dio.dart';
import '../models/provider_model.dart';

class ProviderDataSource {
  final Dio dio;

  const ProviderDataSource({required this.dio});

  Future<List<ProviderModel>> getProviders() async {
    final response = await dio.get('/contents/providers');
    return (response.data['items'] as List)
        .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
