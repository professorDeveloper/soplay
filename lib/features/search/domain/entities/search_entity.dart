import '../../../home/domain/entities/movie.dart';

class SearchEntity {
  final String provider;
  final List<MovieEntity> items;
  final int page;
  final int totalPages;

  SearchEntity({required this.provider, required this.items, required this.page, required this.totalPages});
}
