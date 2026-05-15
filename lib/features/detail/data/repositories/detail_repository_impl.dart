import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/js/js_runtime_service.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/detail/data/datasources/detail_data_source.dart';
import 'package:soplay/features/detail/data/models/detail_model.dart';
import 'package:soplay/features/detail/data/models/media_resolve_model.dart';
import 'package:soplay/features/detail/data/models/playback_model.dart';
import 'package:soplay/features/detail/domain/entities/detail_entity.dart';
import 'package:soplay/features/detail/domain/entities/media_resolve_entity.dart';
import 'package:soplay/features/detail/domain/entities/playback_entity.dart';
import 'package:soplay/features/detail/domain/repositories/detail_repository.dart';

class DetailRepositoryImpl implements DetailRepository {
  final DetailDataSource dataSource;
  final JsRuntimeService? jsRuntime;
  final HiveService? hive;

  const DetailRepositoryImpl(
    this.dataSource, {
    this.jsRuntime,
    this.hive,
  });

  String? _resolveProvider(String? provider) {
    if (provider != null && provider.isNotEmpty) return provider;
    final fromHive = hive?.getCurrentProvider();
    if (fromHive != null && fromHive.isNotEmpty) return fromHive;
    return null;
  }

  @override
  Future<Result<DetailEntity>> getDetail(String contentUrl, {String? provider}) async {
    final js = jsRuntime;
    final effective = _resolveProvider(provider);
    if (js != null && effective != null) {
      try {
        final map = await js.tryGetDetail(effective, contentUrl);
        if (map != null) return Success(DetailModel.fromJson(map));
      } catch (e) {
        return Failure(Exception(_normalizeJsError(e)));
      }
    }
    try {
      return Success(await dataSource.getDetail(contentUrl, provider: effective));
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
    String? provider,
  }) async {
    final js = jsRuntime;
    final effective = _resolveProvider(provider);
    if (js != null && effective != null) {
      try {
        final map = await js.tryGetEpisodes(effective, contentUrl);
        if (map != null) return Success(PlaybackModel.fromJson(map));
      } catch (e) {
        return Failure(Exception(_normalizeJsError(e)));
      }
    }
    try {
      return Success(
        await dataSource.getEpisodes(
          contentUrl,
          page: page,
          size: size,
          sort: sort,
          provider: effective,
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
    final js = jsRuntime;
    if (js != null) {
      try {
        final map = await js.tryResolveMedia(
          provider: provider,
          ref: ref,
          lang: lang,
        );
        if (map != null) {
          return Success(MediaResolveModel.fromJson(map));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[resolveMedia] JS path failed: $e');
        return Failure(Exception(_normalizeJsError(e)));
      }
    }

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

  String _normalizeJsError(Object error) {
    final raw = error.toString();
    if (raw.contains('no playable source')) return 'Video manbasi topilmadi';
    if (raw.contains('Invalid mediaRef')) {
      return 'Provider versiyasi eskirgan';
    }
    if (raw.contains('No servers found')) return 'Episode uchun server yo\'q';
    return raw.replaceFirst('Exception: ', '');
  }

  String _messageFrom(DioException e) {
    return (e.response?.data as Map<String, dynamic>?)?['message']
            as String? ??
        e.message ??
        'Xatolik yuz berdi';
  }
}
