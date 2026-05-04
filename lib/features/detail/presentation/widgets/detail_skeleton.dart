import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E1E1E),
      highlightColor: const Color(0xFF383838),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkBox(width: double.infinity, height: 420 + topPad, radius: 0),
            const _Pad(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _SkBox(width: 50, height: 14, radius: 4),
                      SizedBox(width: 12),
                      _SkBox(width: 60, height: 14, radius: 4),
                      SizedBox(width: 12),
                      _SkBox(width: 70, height: 14, radius: 4),
                    ],
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      _SkBox(width: 60, height: 22, radius: 6),
                      SizedBox(width: 8),
                      _SkBox(width: 80, height: 22, radius: 6),
                      SizedBox(width: 8),
                      _SkBox(width: 70, height: 22, radius: 6),
                    ],
                  ),
                  SizedBox(height: 18),
                  _SkBox(width: double.infinity, height: 13, radius: 4),
                  SizedBox(height: 6),
                  _SkBox(width: double.infinity, height: 13, radius: 4),
                  SizedBox(height: 6),
                  _SkBox(width: 200, height: 13, radius: 4),
                  SizedBox(height: 18),
                  _SkBox(width: double.infinity, height: 46, radius: 6),
                  SizedBox(height: 10),
                  _SkBox(width: double.infinity, height: 46, radius: 6),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionSk(),
                      _ActionSk(),
                      _ActionSk(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _Pad(child: _SkBox(width: 80, height: 16, radius: 5)),
            const SizedBox(height: 12),
            _HorizontalSkRow(count: 6, itemWidth: 60, height: 60, circle: true),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SkBox extends StatelessWidget {
  const _SkBox({required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(width: width, height: height, color: Colors.white),
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}

class _ActionSk extends StatelessWidget {
  const _ActionSk();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(width: 28, height: 28, color: Colors.white),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(width: 36, height: 10, color: Colors.white),
        ),
      ],
    );
  }
}

class _HorizontalSkRow extends StatelessWidget {
  const _HorizontalSkRow({
    required this.count,
    required this.itemWidth,
    required this.height,
    this.circle = false,
  });
  final int count;
  final double itemWidth;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: circle
              ? ClipOval(
                  child: Container(
                    width: itemWidth,
                    height: height,
                    color: Colors.white,
                  ),
                )
              : _SkBox(width: itemWidth, height: height, radius: 10),
        ),
      ),
    );
  }
}
