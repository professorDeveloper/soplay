import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class HomeNetworkImage extends StatelessWidget {
  const HomeNetworkImage({
    super.key,
    required this.url,
    required this.borderRadius,
    required this.placeholderIcon,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) =>
                  HomeImagePlaceholder(icon: placeholderIcon),
              loadingBuilder: (_, child, chunk) => chunk == null
                  ? child
                  : HomeImagePlaceholder(icon: placeholderIcon),
            )
          : HomeImagePlaceholder(icon: placeholderIcon),
    );
  }
}

class HomeImagePlaceholder extends StatelessWidget {
  const HomeImagePlaceholder({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(child: Icon(icon, color: AppColors.textHint, size: 28)),
    );
  }
}

class HomeSkeletonBox extends StatefulWidget {
  const HomeSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<HomeSkeletonBox> createState() => _HomeSkeletonBoxState();
}

class _HomeSkeletonBoxState extends State<HomeSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final sweep = -1.2 + (_controller.value * 2.4);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(sweep, -0.65),
                  end: Alignment(sweep + 0.85, 0.65),
                  colors: const [
                    Color(0xFF252525),
                    Color(0xFF333333),
                    Color(0xFF474747),
                    Color(0xFF333333),
                    Color(0xFF252525),
                  ],
                  stops: const [0.0, 0.28, 0.50, 0.72, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
