import 'package:soplay/features/home/domain/entities/view_all.dart';

import 'movie.dart';

class HomeSectionEntity {
  final String key;
  final String label;
  final ViewAllEntity viewAll;
  final List<MovieEntity> items;

  HomeSectionEntity({
    required this.key,
    required this.viewAll,
    required this.label,
    required this.items,
  });
}
