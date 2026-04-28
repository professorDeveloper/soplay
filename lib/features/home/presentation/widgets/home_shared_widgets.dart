import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';


class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});
  final Animation<double> animation;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  bool updateShouldNotify(_ShimmerScope old) => false;
}

class ShimmerWrapper extends StatefulWidget {
  const ShimmerWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<ShimmerWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(animation: _ctrl, child: widget.child);
}


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


class HomeSkeletonBox extends StatelessWidget {
  const HomeSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  static const _base = Color(0xFF1E1E1E);
  static const _mid = Color(0xFF272727);
  static const _highlight = Color(0xFF383838);

  @override
  Widget build(BuildContext context) {
    final animation = _ShimmerScope.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: animation != null
            ? AnimatedBuilder(
                animation: animation,
                builder: (_, _) {
                  final t = animation.value;
                  final sweep = -1.25 + (t * 2.5);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(sweep, -0.4),
                        end: Alignment(sweep + 0.85, 0.4),
                        colors: const [_base, _mid, _highlight, _mid, _base],
                        stops: const [0.0, 0.28, 0.50, 0.72, 1.0],
                      ),
                    ),
                  );
                },
              )
            : const ColoredBox(color: _base),
      ),
    );
  }
}
