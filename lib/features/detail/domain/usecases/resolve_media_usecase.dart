import 'package:soplay/core/error/result.dart';
import '../entities/media_resolve_entity.dart';
import '../repositories/detail_repository.dart';

class ResolveMediaUseCase {
  final DetailRepository repository;
  const ResolveMediaUseCase(this.repository);

  Future<Result<MediaResolveEntity>> call({
    required String ref,
    required String provider,
    String? lang,
  }) =>
      repository.resolveMedia(ref: ref, provider: provider, lang: lang);
}
