import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/presentation/widgets/home_shared_widgets.dart';
import 'package:soplay/features/home/presentation/widgets/home_ui_helpers.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({
    super.key,
    required this.banners,
    required this.topPadding,
  });

  final List<MovieEntity> banners;
  final double topPadding;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.banners.length < 2) return;
      final next = (_page + 1) % widget.banners.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return HomeBannerSkeleton(topPadding: widget.topPadding);
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
            itemCount: widget.banners.length,
            onPageChanged: (i) => _page = i,
            itemBuilder: (_, index) {
              return AnimatedBuilder(
                animation: _ctrl,
                child: _BannerSlide(movie: widget.banners[index]),
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

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.movie});

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
        const Positioned(
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
                    Color(0xBB181818),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 34,
          child: _BannerInfo(movie: movie),
        ),
      ],
    );
  }
}

class _BannerInfo extends StatelessWidget {
  const _BannerInfo({required this.movie});

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
        SizedBox(height: 8),
        Text(
          movieDescription(movie),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.08,
            letterSpacing: -0.3,
          ),
        ),
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
    return Container(
      height: height,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: AppColors.textHint,
          size: 56,
        ),
      ),
    );
  }
}
