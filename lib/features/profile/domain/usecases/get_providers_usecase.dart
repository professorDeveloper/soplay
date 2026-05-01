import 'package:soplay/core/error/result.dart';
import '../entities/provider_entity.dart';
import '../repositories/provider_repository.dart';

class GetProvidersUseCase {
  final ProviderRepository repository;

  const GetProvidersUseCase(this.repository);

  Future<Result<List<ProviderEntity>>> call() => repository.getProviders();
}
