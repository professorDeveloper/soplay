import 'package:soplay/core/error/result.dart';
import '../entities/detail_entity.dart';
import '../repositories/detail_repository.dart';

class GetDetailUseCase {
  final DetailRepository repository;
  const GetDetailUseCase(this.repository);

  Future<Result<DetailEntity>> call(String contentUrl, {String? provider}) =>
      repository.getDetail(contentUrl, provider: provider);
}
