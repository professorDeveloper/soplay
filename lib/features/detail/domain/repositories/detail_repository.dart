import 'package:soplay/core/error/result.dart';
import '../entities/detail_entity.dart';
import '../entities/media_resolve_entity.dart';
import '../entities/playback_entity.dart';

abstract class DetailRepository {
  Future<Result<DetailEntity>> getDetail(String contentUrl);
  Future<Result<PlaybackEntity>> getEpisodes(
    String contentUrl, {
    int page,
    int size,
    String sort,
  });
  Future<Result<MediaResolveEntity>> resolveMedia({
    required String ref,
    required String provider,
    String? lang,
  });
}
