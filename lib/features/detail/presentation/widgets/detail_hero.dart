import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class DetailHeroBackground extends StatelessWidget {
  const DetailHeroBackground({
    super.key,
    required this.thumbnail,
    required this.title,
  });

  final String? thumbnail;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ThumbnailImage(url: thumbnail),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, 0.4),
              colors: [Color(0xCC000000), Color(0x00000000)],
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    Color(0xEE181818),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Text(
            title.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.3,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 20,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.movie_creation_outlined,
            color: AppColors.textHint,
            size: 64,
          ),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textHint,
            size: 64,
          ),
        ),
      ),
      loadingBuilder: (_, child, chunk) {
        if (chunk == null) return child;
        return Container(color: AppColors.surfaceVariant);
      },
    );
  }
}

class DetailFloatingTopBar extends StatelessWidget {
  const DetailFloatingTopBar({
    super.key,
    required this.onBack,
    this.onBookmark,
    this.isBookmarked = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: topPad + 8, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TopBarButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          if (onBookmark != null)
            _TopBarButton(
              icon: isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              onTap: onBookmark!,
            ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 38,
            height: 38,
            color: Colors.black.withValues(alpha: 0.38),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
