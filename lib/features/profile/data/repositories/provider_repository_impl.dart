import 'package:soplay/core/error/result.dart';
import '../../domain/entities/provider_entity.dart';
import '../../domain/repositories/provider_repository.dart';
import '../datasources/provider_data_source.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final ProviderDataSource dataSource;

  const ProviderRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<ProviderEntity>>> getProviders() async {
    try {
      final providers = await dataSource.getProviders();
      return Success(providers);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
