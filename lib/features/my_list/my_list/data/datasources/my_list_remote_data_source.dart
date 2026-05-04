import 'package:dio/dio.dart';
import 'package:soplay/features/my_list/data/models/favorite_model.dart';

class MyListRemoteDataSource {
  const MyListRemoteDataSource({required this.dio});

  final Dio dio;

  Future<List<FavoriteModel>> getFavorites() async {
    final response = await dio.get('/auth/favorites');
    final data = response.data;
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => FavoriteModel.fromJson(e.cast<String, dynamic>()))
        .where((e) => e.contentUrl.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> addFavorite({
    required String provider,
    required String contentUrl,
    required String title,
    required String thumbnail,
  }) async {
    await dio.post(
      '/auth/favorites',
      data: {
        'provider': provider,
        'contentUrl': contentUrl,
        'title': title,
        'thumbnail': thumbnail,
      },
    );
  }

  Future<void> removeFavorite(String contentUrl) async {
    await dio.delete('/auth/favorites', data: {'contentUrl': contentUrl});
  }
}
