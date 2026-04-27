import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/presentation/bloc/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home_event.dart';
import 'package:soplay/features/home/presentation/widgets/home_banner.dart';
import 'package:soplay/features/home/presentation/widgets/home_shared_widgets.dart';
import 'package:soplay/features/home/presentation/widgets/home_top_bar.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: HomeBannerSkeleton(topPadding: topPad)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HomeSkeletonBox(
                          width: 120,
                          height: 34,
                          radius: 20,
                        ),
                        const SizedBox(width: 8),
                        const HomeSkeletonBox(
                          width: 80,
                          height: 34,
                          radius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (_, i) => const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: HomeSkeletonBox(
                            width: 82,
                            height: 38,
                            radius: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (int i = 0; i < 3; i++) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: HomeSkeletonBox(width: 150, height: 14),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 6,
                    itemBuilder: (_, j) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: HomeSkeletonBox(
                        width: 118,
                        height: 162,
                        radius: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 16,
              ),
            ),
          ],
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeTopBar(blurProgress: 0),
        ),
      ],
    );
  }
}

class HomeErrorView extends StatelessWidget {
  const HomeErrorView({super.key});

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
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                onPressed: () => context.read<HomeBloc>().add(HomeLoad()),
                child: Text('general.retry'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
