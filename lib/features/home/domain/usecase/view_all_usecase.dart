import 'package:soplay/features/home/domain/repositories/home_repository.dart';

import '../../../../core/error/result.dart';
import '../../presentation/bloc/view_all/view_all_event.dart';
import '../entities/view_all_paging_entity.dart';

class ViewAllUseCase {
  final HomeRepository repository;

  ViewAllUseCase(this.repository);

  Future<Result<ViewAllPagingEntity>> call(String key ,String slug ,int page) {
    return repository.loadViewAll(
      key: key,
      slug: slug ?? "",
      page: page,
    );
  }
}
