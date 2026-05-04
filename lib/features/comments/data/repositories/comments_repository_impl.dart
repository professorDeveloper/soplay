import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/comments/data/datasources/comments_data_source.dart';
import 'package:soplay/features/comments/domain/entities/comment_entity.dart';
import 'package:soplay/features/comments/domain/entities/comment_list.dart';
import 'package:soplay/features/comments/domain/entities/like_result.dart';
import 'package:soplay/features/comments/domain/repositories/comments_repository.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  final CommentsDataSource dataSource;
  const CommentsRepositoryImpl(this.dataSource);

  @override
  Future<Result<CommentList>> getComments({
    required String provider,
    required String contentUrl,
    int page = 1,
    int limit = 20,
  }) =>
      _wrap(() => dataSource.getComments(
            provider: provider,
            contentUrl: contentUrl,
            page: page,
            limit: limit,
          ));

  @override
  Future<Result<CommentList>> getReplies({
    required String parentId,
    int page = 1,
    int limit = 20,
  }) =>
      _wrap(() => dataSource.getReplies(
            parentId: parentId,
            page: page,
            limit: limit,
          ));

  @override
  Future<Result<CommentEntity>> create({
    required String provider,
    required String contentUrl,
    required String text,
    String? parentId,
  }) =>
      _wrap(() => dataSource.create(
            provider: provider,
            contentUrl: contentUrl,
            text: text,
            parentId: parentId,
          ));

  @override
  Future<Result<CommentEntity>> edit({
    required String id,
    required String text,
  }) =>
      _wrap(() => dataSource.edit(id: id, text: text));

  @override
  Future<Result<int>> delete(String id) => _wrap(() => dataSource.delete(id));

  @override
  Future<Result<LikeResult>> toggleLike(String id) =>
      _wrap(() => dataSource.toggleLike(id));

  Future<Result<T>> _wrap<T>(Future<T> Function() task) async {
    try {
      return Success(await task());
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) return Failure(Exception('Please sign in first'));
      if (code == 403) return Failure(Exception('Not allowed'));
      if (code == 404) return Failure(Exception('Not found'));
      final raw = (e.response?.data as Map<String, dynamic>?)?['message']
              as String? ??
          e.message ??
          'Something went wrong';
      return Failure(Exception(raw));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
