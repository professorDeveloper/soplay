import 'package:soplay/core/error/result.dart';
import '../entities/provider_entity.dart';

abstract class ProviderRepository {
  Future<Result<List<ProviderEntity>>> getProviders();
}
