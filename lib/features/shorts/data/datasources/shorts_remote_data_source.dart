import 'package:dio/dio.dart';
import 'package:soplay/features/shorts/data/models/short_like_result_model.dart';
import 'package:soplay/features/shorts/data/models/short_model.dart';

class ShortsRemoteDataSource {
  const ShortsRemoteDataSource({required this.dio});

  final Dio dio;

  Future<List<ShortModel>> getShorts() async {
    final response = await dio.get('/shorts');
    final items = _itemsFrom(response.data);
    return items
        .whereType<Map>()
        .map((e) => ShortModel.fromJson(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<ShortModel> getShort(String id) async {
    final response = await dio.get('/shorts/$id');
    final data = response.data;
    final item = data is Map && data['item'] is Map ? data['item'] : data;
    return ShortModel.fromJson((item as Map).cast<String, dynamic>());
  }

  Future<void> increaseView(String id) async {
    await dio.post('/shorts/$id/view');
  }

  Future<ShortLikeResultModel?> toggleLike(String id) async {
    final response = await dio.post('/shorts/$id/like');
    final data = response.data;
    if (data is! Map) return null;
    final item = data['item'];
    final payload = item is Map ? item : data;
    return ShortLikeResultModel.fromJson(payload.cast<String, dynamic>());
  }

  List<dynamic> _itemsFrom(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final items = data['items'] ?? data['data'] ?? data['results'];
      if (items is List) return items;
    }
    return const [];
  }
}
