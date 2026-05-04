import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_state.dart';
import 'package:soplay/features/home/presentation/widgets/home_shared_widgets.dart';
import 'package:soplay/features/home/presentation/widgets/home_ui_helpers.dart';

class ViewAllAppBar extends StatelessWidget {
  const ViewAllAppBar({
    super.key,
    required this.title,
    required this.blurProgress,
  });

  final String title;
  final double blurProgress;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final progress = blurProgress.clamp(0.0, 1.0);

    final content = Container(
      height: topPad + 56,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9 * progress),
        border: progress > 0.05
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07 * progress),
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: EdgeInsets.fromLTRB(4, topPad + 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (progress < 0.01) return content;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20 * progress, sigmaY: 20 * progress),
        child: content,
      ),
    );
  }
}

class ViewAllGrid extends StatelessWidget {
  const ViewAllGrid({
    super.key,
    required this.state,
    required this.scroll,
    required this.appBarH,
  });

  final ViewAllLoaded state;
  final ScrollController scroll;
  final double appBarH;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      controller: scroll,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, appBarH + 12, 12, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, index) => ViewAllMovieCard(movie: state.items[index]),
              childCount: state.items.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 8,
              childAspectRatio: 0.52,
            ),
          ),
        ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPad + 16)),
      ],
    );
  }
}


class ViewAllMovieCard extends StatelessWidget {
  const ViewAllMovieCard({super.key, required this.movie});

  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    final quality = primaryQuality(movie);

    return GestureDetector(
      onTap: () {
        if (movie.url.isNotEmpty) {
          context.push('/detail', extra: DetailArgs(contentUrl: movie.url, preview: movie));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HomeNetworkImage(
                    url: movie.thumbnail,
                    borderRadius: BorderRadius.zero,
                    placeholderIcon: Icons.movie_outlined,
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xAA000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (quality != null)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quality,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            movieTitle(movie),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if (movie.year != null)
            Text(
              movie.year.toString(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}


class ViewAllSkeleton extends StatelessWidget {
  const ViewAllSkeleton({super.key, required this.appBarH});

  final double appBarH;

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, appBarH + 12, 12, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, _) => const _SkeletonGridCard(),
                childCount: 15,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 8,
                childAspectRatio: 0.52,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonGridCard extends StatelessWidget {
  const _SkeletonGridCard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HomeSkeletonBox(
            width: double.infinity,
            height: double.infinity,
            radius: 10,
          ),
        ),
        SizedBox(height: 5),
        HomeSkeletonBox(width: double.infinity, height: 10, radius: 3),
        SizedBox(height: 3),
        HomeSkeletonBox(width: 50, height: 10, radius: 3),
      ],
    );
  }
}


class ViewAllErrorView extends StatelessWidget {
  const ViewAllErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'errors.network'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'general.try_again'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 156,
              height: 44,
              child: ElevatedButton(
                onPressed: onRetry,
                child: Text('general.retry'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
