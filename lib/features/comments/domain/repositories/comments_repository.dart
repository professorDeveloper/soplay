import 'package:soplay/core/error/result.dart';
import '../entities/comment_entity.dart';
import '../entities/comment_list.dart';
import '../entities/like_result.dart';

abstract class CommentsRepository {
  Future<Result<CommentList>> getComments({
    required String provider,
    required String contentUrl,
    int page,
    int limit,
  });

  Future<Result<CommentList>> getReplies({
    required String parentId,
    int page,
    int limit,
  });

  Future<Result<CommentEntity>> create({
    required String provider,
    required String contentUrl,
    required String text,
    String? parentId,
  });

  Future<Result<CommentEntity>> edit({
    required String id,
    required String text,
  });

  Future<Result<int>> delete(String id);

  Future<Result<LikeResult>> toggleLike(String id);
}
