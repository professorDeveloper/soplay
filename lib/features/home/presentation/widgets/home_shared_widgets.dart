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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
