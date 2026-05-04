import 'package:flutter/material.dart';
import 'package:soplay/features/home/presentation/widgets/home_shared_widgets.dart';

class MyListSkeleton extends StatelessWidget {
  const MyListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 142,
          mainAxisSpacing: 16,
          crossAxisSpacing: 10,
          childAspectRatio: 0.56,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => const _SkeletonCard(),
          childCount: 9,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const ShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: HomeSkeletonBox(
              width: double.infinity,
              height: 1,
              radius: 10,
            ),
          ),
          SizedBox(height: 7),
          HomeSkeletonBox(width: double.infinity, height: 12, radius: 4),
          SizedBox(height: 5),
          HomeSkeletonBox(width: 72, height: 10, radius: 4),
        ],
      ),
    );
  }
}
