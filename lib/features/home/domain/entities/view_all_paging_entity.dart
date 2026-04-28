import 'package:soplay/features/home/domain/entities/movie.dart';

class ViewAllPagingEntity {
  final int page;
  final int totalPages;
  final String provider;
  final List<MovieEntity> items;

  ViewAllPagingEntity({
    required this.page,
    required this.totalPages,
    required this.provider,
    required this.items,
  });
}
