import 'package:dio/dio.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/detail/data/datasources/detail_data_source.dart';
import 'package:soplay/features/detail/domain/entities/detail_entity.dart';
import 'package:soplay/features/detail/domain/entities/media_resolve_entity.dart';
import 'package:soplay/features/detail/domain/entities/playback_entity.dart';
import 'package:soplay/features/detail/domain/repositories/detail_repository.dart';

class DetailRepositoryImpl implements DetailRepository {
  final DetailDataSource dataSource;
  const DetailRepositoryImpl(this.dataSource);

  @override
  Future<Result<DetailEntity>> getDetail(String contentUrl) async {
    try {
      return Success(await dataSource.getDetail(contentUrl));
    } on DioException catch (e) {
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<PlaybackEntity>> getEpisodes(
    String contentUrl, {
    int page = 1,
    int size = 100,
    String sort = 'asc',
  }) async {
    try {
      return Success(
        await dataSource.getEpisodes(
          contentUrl,
          page: page,
          size: size,
          sort: sort,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) {
        return Failure(
          Exception('Provider epizodlarni qo\'llab-quvvatlamaydi'),
        );
      }
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<MediaResolveEntity>> resolveMedia({
    required String ref,
    required String provider,
    String? lang,
  }) async {
    try {
      return Success(
        await dataSource.resolveMedia(
          ref: ref,
          provider: provider,
          lang: lang,
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 422) {
        return Failure(Exception('Video URL aniqlanmadi'));
      }
      if (code == 501) {
        return Failure(
          Exception('Provider media yechishni qo\'llab-quvvatlamaydi'),
        );
      }
      return Failure(Exception(_messageFrom(e)));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  String _messageFrom(DioException e) {
    return (e.response?.data as Map<String, dynamic>?)?['message']
            as String? ??
        e.message ??
        'Xatolik yuz berdi';
  }
}
