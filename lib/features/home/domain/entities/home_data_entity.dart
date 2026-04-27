import 'home_section_entity.dart';
import 'content_filter_entity.dart';
import 'movie.dart';

class HomeDataEntity {
  final String provider;
  final List<MovieEntity> banner;
  final List<HomeSectionEntity> sections;
  final List<ContentFilterEntity> categories;
  final List<ContentFilterEntity> genres;

  HomeDataEntity({
    required this.provider,
    required this.banner,
    required this.sections,
    required this.categories,
    required this.genres,
  });
}
