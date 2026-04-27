import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.blurProgress});

  final double blurProgress;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final progress = blurProgress.clamp(0.0, 1.0);
    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.80 * (1 - progress)),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
        color: AppColors.navBackground.withValues(alpha: 0.72 * progress),
        border: progress > 0.05
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06 * progress),
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 10, 12, 10),
      child: Row(
        children: [
          const Text(
            'SOPLAY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              height: 1,
            ),
          ),
          const Spacer(),
          _TopBarIcon(icon: Icons.search_rounded, onTap: () {}),
          _TopBarIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
        ],
      ),
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18 * progress, sigmaY: 18 * progress),
        child: content,
      ),
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
