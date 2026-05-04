import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';
import 'package:soplay/features/my_list/domain/repositories/my_list_repository.dart';

class AddFavoriteUseCase {
  const AddFavoriteUseCase(this.repository);

  final MyListRepository repository;

  Future<Result<void>> call(FavoriteEntity entity) =>
      repository.addFavorite(entity);
}
