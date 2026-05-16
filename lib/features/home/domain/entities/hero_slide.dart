import 'package:soplay/features/banners/domain/entities/banner_item.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';

sealed class HeroSlide {
  const HeroSlide();
}

class MovieHeroSlide extends HeroSlide {
  final MovieEntity movie;
  const MovieHeroSlide(this.movie);
}

class BannerHeroSlide extends HeroSlide {
  final BannerItem banner;
  const BannerHeroSlide(this.banner);
}
