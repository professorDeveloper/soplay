import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/my_list/data/datasources/my_list_remote_data_source.dart';
import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';
import 'package:soplay/features/my_list/domain/entities/my_list_failure.dart';
import 'package:soplay/features/my_list/domain/repositories/my_list_repository.dart';

class MyListRepositoryImpl implements MyListRepository {
  const MyListRepositoryImpl(this.dataSource);

  final MyListRemoteDataSource dataSource;

  @override
  Future<Result<List<FavoriteEntity>>> getFavorites() async {
    try {
      return Success(await dataSource.getFavorites());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Failure(MyListUnauthorizedException());
      }
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> addFavorite(FavoriteEntity entity) async {
    try {
      await dataSource.addFavorite(
        provider: entity.provider,
        contentUrl: entity.contentUrl,
        title: entity.title,
        thumbnail: entity.thumbnail,
      );
      return Success<void>(null);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeFavorite(String contentUrl) async {
    try {
      await dataSource.removeFavorite(contentUrl);
      return Success<void>(null);
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }
    return e.message ?? 'Request failed';
  }
}
