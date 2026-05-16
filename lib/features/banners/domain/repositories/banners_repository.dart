import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/banners/domain/entities/banner_item.dart';

abstract class BannersRepository {
  Future<Result<List<BannerItem>>> list(String placement);
  Future<void> trackView(String id);
  Future<void> trackClick(String id);
}
