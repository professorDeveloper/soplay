import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/shorts/domain/entities/short_like_result.dart';
import 'package:soplay/features/shorts/domain/repositories/shorts_repository.dart';

class ToggleShortLikeUseCase {
  const ToggleShortLikeUseCase(this.repository);

  final ShortsRepository repository;

  Future<Result<ShortLikeResult?>> call(String id) => repository.toggleLike(id);
}
