import '../../../../core/error/result.dart';
import '../entities/home_data_entity.dart';
import '../repositories/home_repository.dart';

class HomeUseCase {
  final HomeRepository homeRepository;

  const HomeUseCase(this.homeRepository);

  Future<Result<HomeDataEntity>> call() => homeRepository.loadHome();
}
