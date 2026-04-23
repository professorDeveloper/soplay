import 'home_section_entity.dart';
import 'movie.dart';

class HomeDataEntity {
  final String provider;
  final List<MovieEntity> banner;
  final List<HomeSectionEntity> sections;

  HomeDataEntity({
    required this.provider,
    required this.banner,
    required this.sections,
  });
}
