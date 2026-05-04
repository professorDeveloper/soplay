import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/domain/entities/short_like_result.dart';

abstract class ShortsRepository {
  Future<Result<List<ShortEntity>>> getShorts();
  Future<Result<ShortEntity>> getShort(String id);
  Future<Result<void>> increaseView(String id);
  Future<Result<ShortLikeResult?>> toggleLike(String id);
}
