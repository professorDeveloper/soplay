import 'package:dio/dio.dart';
import '../models/provider_model.dart';

class ProviderDataSource {
  final Dio dio;

  const ProviderDataSource({required this.dio});

  Future<List<ProviderModel>> getProviders() async {
    final response = await dio.get(
      '/contents/providers',
      options: Options(extra: const {'skipAuthInterceptor': true}),
    );
    final data = response.data;
    final items = switch (data) {
      {'items': final List items} => items,
      {'data': final List items} => items,
      final List items => items,
      _ => const [],
    };

    return items
        .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
