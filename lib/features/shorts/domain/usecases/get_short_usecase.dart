import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/domain/repositories/shorts_repository.dart';

class GetShortUseCase {
  const GetShortUseCase(this.repository);

  final ShortsRepository repository;

  Future<Result<ShortEntity>> call(String id) => repository.getShort(id);
}
