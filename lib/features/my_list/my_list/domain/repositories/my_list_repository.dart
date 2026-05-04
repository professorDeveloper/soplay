import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';

abstract class MyListRepository {
  Future<Result<List<FavoriteEntity>>> getFavorites();
  Future<Result<void>> addFavorite(FavoriteEntity entity);
  Future<Result<void>> removeFavorite(String contentUrl);
}
