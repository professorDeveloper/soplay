import 'package:dio/dio.dart';
import 'package:soplay/features/comments/data/models/comment_list_model.dart';
import 'package:soplay/features/comments/data/models/comment_model.dart';
import 'package:soplay/features/comments/domain/entities/like_result.dart';

class CommentsDataSource {
  final Dio dio;
  const CommentsDataSource({required this.dio});

  Future<CommentListModel> getComments({
    required String provider,
    required String contentUrl,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await dio.get(
      '/comments',
      queryParameters: {
        'provider': provider,
        'contentUrl': contentUrl,
        'page': page,
        'limit': limit,
      },
    );
    return CommentListModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CommentListModel> getReplies({
    required String parentId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await dio.get(
      '/comments/$parentId/replies',
      queryParameters: {'page': page, 'limit': limit},
    );
    return CommentListModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CommentModel> create({
    required String provider,
    required String contentUrl,
    required String text,
    String? parentId,
  }) async {
    final payload = <String, dynamic>{
      'provider': provider,
      'contentUrl': contentUrl,
      'text': text,
    };
    if (parentId != null) payload['parentId'] = parentId;
    final res = await dio.post('/comments', data: payload);
    final body = res.data as Map<String, dynamic>;
    return CommentModel.fromJson(
      (body['item'] as Map).cast<String, dynamic>(),
    );
  }

  Future<CommentModel> edit({
    required String id,
    required String text,
  }) async {
    final res = await dio.put('/comments/$id', data: {'text': text});
    final body = res.data as Map<String, dynamic>;
    return CommentModel.fromJson(
      (body['item'] as Map).cast<String, dynamic>(),
    );
  }

  Future<int> delete(String id) async {
    final res = await dio.delete('/comments/$id');
    final body = res.data as Map<String, dynamic>;
    return (body['cascadeDeleted'] as num?)?.toInt() ?? 0;
  }

  Future<LikeResult> toggleLike(String id) async {
    final res = await dio.post('/comments/$id/like');
    final body = res.data as Map<String, dynamic>;
    return LikeResult(
      liked: body['liked'] as bool? ?? false,
      likeCount: (body['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
