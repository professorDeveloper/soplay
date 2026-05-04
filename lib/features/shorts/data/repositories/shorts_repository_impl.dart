import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/shorts/data/datasources/shorts_remote_data_source.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/domain/entities/short_like_result.dart';
import 'package:soplay/features/shorts/domain/entities/shorts_feed_result.dart';
import 'package:soplay/features/shorts/domain/repositories/shorts_repository.dart';

class ShortsRepositoryImpl implements ShortsRepository {
  const ShortsRepositoryImpl(this.dataSource);

  final ShortsRemoteDataSource dataSource;

  @override
  Future<Result<ShortsFeedResult>> getShortsFeed({
    String? cursor,
    int limit = 15,
  }) async {
    try {
      return Success(
        await dataSource.getShortsFeed(cursor: cursor, limit: limit),
      );
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<ShortEntity>> getShort(String id) async {
    try {
      return Success(await dataSource.getShort(id));
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> increaseView(String id) async {
    try {
      await dataSource.increaseView(id);
      return Success<void>(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<ShortLikeResult?>> toggleLike(String id) async {
    try {
      return Success(await dataSource.toggleLike(id));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Failure(Exception('Please sign in to like'));
      }
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return e.message ?? 'Something went wrong';
  }
}
