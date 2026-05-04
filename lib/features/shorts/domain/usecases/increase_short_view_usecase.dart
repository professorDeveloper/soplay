import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/shorts/domain/repositories/shorts_repository.dart';

class IncreaseShortViewUseCase {
  const IncreaseShortViewUseCase(this.repository);

  final ShortsRepository repository;

  Future<Result<void>> call(String id) => repository.increaseView(id);
}
