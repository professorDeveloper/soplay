import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/banners/domain/entities/banner_item.dart';
import 'package:soplay/features/banners/presentation/bloc/banners_bloc.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/home/domain/entities/hero_slide.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/presentation/widgets/home_shared_widgets.dart';
import 'package:soplay/features/home/presentation/widgets/home_ui_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({
    super.key,
    required this.slides,
    required this.topPadding,
    this.showSkeleton = true,
  });

  final List<HeroSlide> slides;
  final double topPadding;
  final bool showSkeleton;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;
  final Set<String> _trackedBanners = {};

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _startTimer();
    _trackBannerView(0);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.slides.length < 2) return;
      final next = (_page + 1) % widget.slides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _trackBannerView(int index) {
    if (index >= widget.slides.length) return;
    final slide = widget.slides[index];
    if (slide is BannerHeroSlide && _trackedBanners.add(slide.banner.id)) {
      if (mounted) {
        context.read<BannersBloc>().add(BannersView(slide.banner.id));
      }
    }
  }

  Future<void> _onBannerTap(BannerItem item) async {
    context.read<BannersBloc>().add(BannersClick(item.id));
    final link = item.link;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      return widget.showSkeleton
          ? HomeBannerSkeleton(topPadding: widget.topPadding)
          : const SizedBox.shrink();
    }
    final height = (MediaQuery.of(context).size.height * 0.63).clamp(
      440.0,
      480.0,
    );

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            allowImplicitScrolling: true,
            physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
            itemCount: widget.slides.length,
            onPageChanged: (i) {
              _page = i;
              _trackBannerView(i);
            },
            itemBuilder: (_, index) {
              final slide = widget.slides[index];
              return AnimatedBuilder(
                animation: _ctrl,
                child: _SlideContent(slide: slide, onBannerTap: _onBannerTap),
                builder: (context, child) {
                  var page = index.toDouble();
                  if (_ctrl.position.haveDimensions) {
                    page = _ctrl.page ?? page;
                  }
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1.0 - (distance * 0.035);
                  final opacity = 1.0 - (distance * 0.18);

                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide, required this.onBannerTap});

  final HeroSlide slide;
  final Future<void> Function(BannerItem item) onBannerTap;

  @override
  Widget build(BuildContext context) {
    return switch (slide) {
      MovieHeroSlide(:final movie) => _MovieSlide(movie: movie),
      BannerHeroSlide(:final banner) => _BannerSlide(
          banner: banner,
          onTap: () => onBannerTap(banner),
        ),
    };
  }
}

class _MovieSlide extends StatelessWidget {
  const _MovieSlide({required this.movie});

  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (movie.url.isNotEmpty) {
          context.push(
            '/detail',
            extra: DetailArgs(contentUrl: movie.url, preview: movie),
          );
        }
      },
      child: _MovieSlideContent(movie: movie),
    );
  }
}

class _MovieSlideContent extends StatelessWidget {
  const _MovieSlideContent({required this.movie});
  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HomeNetworkImage(
          url: movie.thumbnail,
          borderRadius: BorderRadius.zero,
          placeholderIcon: Icons.movie_creation_outlined,
        ),
        const _SlideOverlays(),
        Positioned(
          left: 20,
          right: 20,
          bottom: 34,
          child: _MovieInfo(movie: movie),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner, required this.onTap});

  final BannerItem banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const ColoredBox(
              color: AppColors.surfaceVariant,
            ),
          ),
          const _SlideOverlays(),
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: _BannerInfo(banner: banner),
          ),
        ],
      ),
    );
  }
}

class _SlideOverlays extends StatelessWidget {
  const _SlideOverlays();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0xBB000000), Color(0x00000000)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0x55000000), Color(0x00000000)],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    const Color(0xBB181818),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.52, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieInfo extends StatelessWidget {
  const _MovieInfo({required this.movie});

  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    final meta = movieMetaLabels(movie);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: meta.take(4).map((m) => _MetaChip(label: m)).toList(),
          ),
        const SizedBox(height: 10),
        Text(
          movieTitle(movie),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 16,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          movieDescription(movie),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.08,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _BannerInfo extends StatelessWidget {
  const _BannerInfo({required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          banner.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.3,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 16,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            banner.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.08,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class HomeBannerSkeleton extends StatelessWidget {
  const HomeBannerSkeleton({super.key, required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.of(context).size.height * 0.63).clamp(
      460.0,
      580.0,
    );
    return SizedBox(
      height: height,
      child: const HomeSkeletonBox(
        width: double.infinity,
        height: double.infinity,
        radius: 0,
      ),
    );
  }
}
