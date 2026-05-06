import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/navigation/nav_controller.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';
import 'package:soplay/features/download/data/download_service.dart';
import 'package:soplay/features/download/domain/entities/download_item.dart';

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
            'SOZO',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              height: 1,
            ),
          ),
          const Spacer(),
          _TopBarIcon(
            icon: Icons.search_rounded,
            onTap: () => getIt<NavController>().goTo(1),
          ),
          _DownloadIndicator(),
          _TopBarIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
          const SizedBox(width: 2),
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (a, b) => a.runtimeType != b.runtimeType,
            builder: (context, state) {
              if (state is AuthLoaded) {
                final name = state.token.user.displayIdentifier;
                final initial =
                    name.isEmpty ? 'U' : name[0].toUpperCase();
                return GestureDetector(
                  onTap: () => getIt<NavController>().goTo(4),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );

    if (progress < 0.01) return content;

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

class _DownloadIndicator extends StatefulWidget {
  @override
  State<_DownloadIndicator> createState() => _DownloadIndicatorState();
}

class _DownloadIndicatorState extends State<_DownloadIndicator>
    with SingleTickerProviderStateMixin {
  final DownloadService _service = getIt<DownloadService>();
  late final AnimationController _pulse;
  bool _hasActive = false;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _service.revision.addListener(_check);
    _check();
  }

  @override
  void dispose() {
    _service.revision.removeListener(_check);
    _pulse.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final items = _service.getAll();
    final active = items.where((i) => i.status == DownloadStatus.downloading).length;
    final hasActive = active > 0;
    if (hasActive != _hasActive || active != _activeCount) {
      setState(() {
        _hasActive = hasActive;
        _activeCount = active;
      });
      if (hasActive) {
        _pulse.repeat();
      } else {
        _pulse.stop();
        _pulse.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActive) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/downloads'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Icon(
                    Icons.download_rounded,
                    color: Color.lerp(
                      AppColors.primary,
                      Colors.white,
                      (_pulse.value * 2 - 1).abs(),
                    ),
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
