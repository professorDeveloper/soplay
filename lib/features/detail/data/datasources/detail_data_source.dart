import 'package:dio/dio.dart';
import 'package:soplay/features/detail/data/models/detail_model.dart';
import 'package:soplay/features/detail/data/models/media_resolve_model.dart';
import 'package:soplay/features/detail/data/models/playback_model.dart';

class DetailDataSource {
  final Dio dio;
  const DetailDataSource({required this.dio});

  Future<DetailModel> getDetail(String contentUrl) async {
    final response = await dio.get(
      '/contents/detail',
      queryParameters: {'url': contentUrl},
    );
    return DetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlaybackModel> getEpisodes(
    String contentUrl, {
    int page = 1,
    int size = 100,
    String sort = 'asc',
  }) async {
    final response = await dio.get(
      '/contents/episodes',
      queryParameters: {
        'url': contentUrl,
        'page': page,
        'size': size,
        'sort': sort,
      },
    );
    return PlaybackModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MediaResolveModel> resolveMedia({
    required String ref,
    required String provider,
    String? lang,
  }) async {
    final response = await dio.get(
      '/contents/media',
      queryParameters: {
        'ref': ref,
        'provider': provider,
        if (lang != null && lang.isNotEmpty) 'lang': lang,
      },
    );
    return MediaResolveModel.fromJson(response.data as Map<String, dynamic>);
  }
}
