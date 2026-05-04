import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/domain/repositories/shorts_repository.dart';

class GetShortsUseCase {
  const GetShortsUseCase(this.repository);

  final ShortsRepository repository;

  Future<Result<List<ShortEntity>>> call() => repository.getShorts();
}
