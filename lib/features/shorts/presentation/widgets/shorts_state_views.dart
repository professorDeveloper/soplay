import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class ShortsLoadingView extends StatelessWidget {
  const ShortsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.6,
        ),
      ),
    );
  }
}

class ShortsEmptyView extends StatelessWidget {
  const ShortsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShortsMessage(
      icon: Icons.video_library_outlined,
      title: 'No shorts yet',
      message: 'Short scenes will appear here.',
    );
  }
}

class ShortsErrorView extends StatelessWidget {
  const ShortsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ShortsMessage(
      icon: Icons.error_outline_rounded,
      title: 'Could not load shorts',
      message: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _ShortsMessage extends StatelessWidget {
  const _ShortsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 42),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
