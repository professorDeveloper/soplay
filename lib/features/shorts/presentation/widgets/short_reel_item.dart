import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:video_player/video_player.dart';

class ShortReelItem extends StatelessWidget {
  const ShortReelItem({
    super.key,
    required this.short,
    required this.active,
    required this.likeLoading,
    required this.onLike,
  });

  final ShortEntity short;
  final bool active;
  final bool likeLoading;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 92;
    final topPad = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        _BlurBackdrop(thumbnail: short.thumbnail),
        ShortVideoSurface(
          videoUrl: short.videoUrl,
          thumbnail: short.thumbnail,
          active: active,
        ),
        const _ReelGradient(),
        Positioned(
          top: topPad + 14,
          left: 18,
          child: const Text(
            'Shorts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: bottomPad + 8,
          child: _ActionsColumn(
            short: short,
            likeLoading: likeLoading,
            onLike: onLike,
          ),
        ),
        Positioned(
          left: 18,
          right: 86,
          bottom: bottomPad,
          child: _ShortInfo(short: short),
        ),
      ],
    );
  }
}

class ShortVideoSurface extends StatefulWidget {
  const ShortVideoSurface({
    super.key,
    required this.videoUrl,
    required this.thumbnail,
    required this.active,
  });

  final String videoUrl;
  final String thumbnail;
  final bool active;

  @override
  State<ShortVideoSurface> createState() => _ShortVideoSurfaceState();
}

class _ShortVideoSurfaceState extends State<ShortVideoSurface> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant ShortVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      unawaited(_reset());
      return;
    }
    _syncPlayback();
  }

  Future<void> _reset() async {
    await _disposeController();
    if (!mounted) return;
    await _open();
  }

  Future<void> _open() async {
    if (widget.videoUrl.trim().isEmpty) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _ready = true);
      _syncPlayback();
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (widget.active) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    _ready = false;
    if (controller == null) return;
    await controller.dispose();
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return _Poster(thumbnail: widget.thumbnail);
    }

    final size = controller.value.size;
    final width = size.width <= 0 ? 1080.0 : size.width;
    final height = size.height <= 0 ? 1920.0 : size.height;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: width,
        height: height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.thumbnail});

  final String thumbnail;

  @override
  Widget build(BuildContext context) {
    if (thumbnail.isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white38,
            size: 72,
          ),
        ),
      );
    }
    return Image.network(
      thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
    );
  }
}

class _BlurBackdrop extends StatelessWidget {
  const _BlurBackdrop({required this.thumbnail});

  final String thumbnail;

  @override
  Widget build(BuildContext context) {
    if (thumbnail.isEmpty) return const ColoredBox(color: Colors.black);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          thumbnail,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.36)),
        ),
      ],
    );
  }
}

class _ReelGradient extends StatelessWidget {
  const _ReelGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x99000000),
            Color(0x14000000),
            Color(0x00000000),
            Color(0x66000000),
            Color(0xDD000000),
          ],
          stops: [0, 0.22, 0.48, 0.74, 1],
        ),
      ),
    );
  }
}

class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({
    required this.short,
    required this.likeLoading,
    required this.onLike,
  });

  final ShortEntity short;
  final bool likeLoading;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: short.likedByMe ? Icons.favorite : Icons.favorite_border,
          color: short.likedByMe ? AppColors.primaryLight : Colors.white,
          loading: likeLoading,
          onTap: onLike,
        ),
        const SizedBox(height: 5),
        Text(
          _compact(short.likeCount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.visibility_rounded,
          color: Colors.white,
          onTap: () {},
        ),
        const SizedBox(height: 5),
        Text(
          _compact(short.viewCount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.34),
          child: InkWell(
            onTap: loading ? null : onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: color, size: 25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortInfo extends StatelessWidget {
  const _ShortInfo({required this.short});

  final ShortEntity short;

  @override
  Widget build(BuildContext context) {
    final author = short.author.trim();
    final title = short.title.trim();
    final description = short.description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (author.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

String _compact(int value) {
  if (value >= 1000000) {
    final text = (value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1);
    return '${text.replaceAll('.0', '')}M';
  }
  if (value >= 1000) {
    final text = (value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1);
    return '${text.replaceAll('.0', '')}K';
  }
  return value.toString();
}
