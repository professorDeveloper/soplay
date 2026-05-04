import 'package:dio/dio.dart';
import 'package:soplay/features/shorts/data/models/short_like_result_model.dart';
import 'package:soplay/features/shorts/data/models/short_model.dart';
import 'package:soplay/features/shorts/domain/entities/shorts_feed_result.dart';

class ShortsRemoteDataSource {
  const ShortsRemoteDataSource({required this.dio});

  final Dio dio;

  Future<ShortsFeedResult> getShortsFeed({
    String? cursor,
    String? query,
    int limit = 15,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

    final response = await dio.get('/shorts/feed', queryParameters: params);
    final data = response.data;

    final rawItems = data is Map
        ? (data['items'] ?? const [])
        : (data is List ? data : const []);

    final items = (rawItems as List)
        .whereType<Map>()
        .map((e) => ShortModel.fromJson(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty && e.videoUrl.isNotEmpty)
        .toList(growable: false);

    final nextCursor = data is Map ? (data['nextCursor'] as String?) : null;
    final hasMore = data is Map
        ? (data['hasMore'] as bool? ?? nextCursor != null)
        : false;

    return ShortsFeedResult(
      items: items,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
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
}
