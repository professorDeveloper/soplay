import 'movie.dart';

class HomeSectionEntity {
  final String key;
  final String label;
  final List<MovieEntity> items;

  HomeSectionEntity({
    required this.key,
    required this.label,
    required this.items,
  });
}
