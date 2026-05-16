import 'package:dio/dio.dart';
import 'package:soplay/features/banners/data/models/banner_item_model.dart';

class BannersDataSource {
  final Dio dio;
  const BannersDataSource({required this.dio});

  Future<List<BannerItemModel>> list(String placement) async {
    final res = await dio.get(
      '/banners',
      queryParameters: {'placement': placement},
      options: Options(extra: const {'skipAuthInterceptor': true}),
    );
    final data = res.data;
    final items = switch (data) {
      {'items': final List items} => items,
      {'data': final List items} => items,
      final List items => items,
      _ => const [],
    };
    return items
        .whereType<Map>()
        .map((e) => BannerItemModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> view(String id) async {
    await dio.post(
      '/banners/$id/view',
      options: Options(extra: const {'skipAuthInterceptor': true}),
    );
  }

  Future<void> click(String id) async {
    await dio.post(
      '/banners/$id/click',
      options: Options(extra: const {'skipAuthInterceptor': true}),
    );
  }
}
