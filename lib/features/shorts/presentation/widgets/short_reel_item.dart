import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/short_entity.dart';

/// A single short reel item — YouTube Shorts style, fully redesigned.
///
/// Controls:
///  • Tap anywhere       → toggle play / pause (shows overlay)
///  • Double-tap         → like (heart burst)
///  • Seekbar            → scrub with time labels
///  • Side rail          → like, share, open detail
///  • "View in Movie"    → pill button at bottom → onOpenDetail
///  • Author row         → avatar + name at bottom-left
class ShortReelItem extends StatefulWidget {
  const ShortReelItem({
    super.key,
    required this.short,
    required this.active,
    required this.likeLoading,
    required this.onLike,
    required this.onOpenDetail,
  });

  final ShortEntity short;
  final bool active;
  final bool likeLoading;
  final VoidCallback onLike;
  final VoidCallback onOpenDetail;

  @override
  State<ShortReelItem> createState() => _ShortReelItemState();
}

class _ShortReelItemState extends State<ShortReelItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _vpc;

  bool _showControls = false;
  bool _hasError = false;

  late final AnimationController _overlayAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _overlayFade = CurvedAnimation(
    parent: _overlayAnim,
    curve: Curves.easeInOut,
  );

  bool _showHeart = false;
  Offset _heartPos = Offset.zero;

  bool _seeking = false;
  double _seekValue = 0;

  static const _hideDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant ShortReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (!widget.active) {
        _vpc?.pause();
        _hideControlsNow();
      } else {
        _vpc?.play();
      }
    }
  }

  @override
  void dispose() {
    _overlayAnim.dispose();
    _vpc?.removeListener(_onPlayerTick);
    _vpc?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final url = widget.short.videoUrl.trim();
    if (url.isEmpty) return;

    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _vpc = c;
      await c.initialize();
      if (!mounted) return;
      c.setLooping(true);
      c.addListener(_onPlayerTick);
      if (widget.active) c.play();
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onPlayerTick() {
    if (mounted) setState(() {});
  }

  Duration get _position => _vpc?.value.position ?? Duration.zero;
  Duration get _duration => _vpc?.value.duration ?? Duration.zero;
  bool get _isPlaying => _vpc?.value.isPlaying ?? false;
  bool get _initialized => _vpc?.value.isInitialized ?? false;
  bool get _isBuffering => _vpc?.value.isBuffering ?? false;

  double get _progress {
    if (!_initialized) return 0;
    final ms = _duration.inMilliseconds;
    if (ms == 0) return 0;
    return (_position.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleControls() {
    if (_showControls) {
      _hideControlsNow();
    } else {
      setState(() => _showControls = true);
      _overlayAnim.forward();
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    Future.delayed(_hideDelay, () {
      if (mounted && _showControls && !_seeking) _hideControlsNow();
    });
  }

  void _hideControlsNow() {
    if (!mounted) return;
    _overlayAnim.reverse().then((_) {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (_showControls) {
      _isPlaying ? _vpc?.pause() : _vpc?.play();
      _scheduleHide();
    } else {
      _toggleControls();
    }
  }

  void _onDoubleTap(TapDownDetails d) {
    HapticFeedback.mediumImpact();
    widget.onLike();
    setState(() {
      _heartPos = d.localPosition;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _onSeekStart(double v) {
    _seeking = true;
    setState(() => _seekValue = v);
  }

  void _onSeekUpdate(double v) => setState(() => _seekValue = v);

  Future<void> _onSeekEnd(double v) async {
    _seeking = false;
    final ms = (_duration.inMilliseconds * v).round();
    await _vpc?.seekTo(Duration(milliseconds: ms));
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      onDoubleTapDown: _onDoubleTap,
      onDoubleTap: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── video / thumbnail ─────────────────────────────────────────────
          _VideoBackground(vpc: _vpc, short: widget.short),

          // ── top scrim (for safe-area readability) ─────────────────────────
          const _TopScrim(),

          // ── bottom gradient scrim ─────────────────────────────────────────
          const _BottomScrim(),

          // ── error overlay ─────────────────────────────────────────────────
          if (_hasError) const _ErrorOverlay(),

          // ── buffering spinner ─────────────────────────────────────────────
          if (_initialized && _isBuffering && !_hasError)
            const Center(child: _BufferingSpinner()),

          // ── loading spinner (not yet initialized) ─────────────────────────
          if (!_initialized && !_hasError)
            const Center(child: _BufferingSpinner()),

          // ── centre play/pause ─────────────────────────────────────────────
          if (_showControls)
            FadeTransition(
              opacity: _overlayFade,
              child: Center(
                child: _PlayPauseButton(
                  isPlaying: _isPlaying,
                  onTap: () {
                    _isPlaying ? _vpc?.pause() : _vpc?.play();
                    _scheduleHide();
                  },
                ),
              ),
            ),

          // ── side rail ─────────────────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: 130,
            child: _SideRail(
              short: widget.short,
              likeLoading: widget.likeLoading,
              onLike: widget.onLike,
              onOpenDetail: widget.onOpenDetail,
            ),
          ),

          // ── bottom meta: author + title + "View in Movie" + seekbar ───────
          Positioned(
            left: 0,
            right: 76,
            bottom: 0,
            child: _BottomMeta(
              short: widget.short,
              position: _position,
              duration: _duration,
              progress: _seeking ? _seekValue : _progress,
              fmt: _fmt,
              showControls: _showControls,
              overlayFade: _overlayFade,
              onSeekStart: _onSeekStart,
              onSeekUpdate: _onSeekUpdate,
              onSeekEnd: _onSeekEnd,
              onOpenDetail: widget.onOpenDetail,
            ),
          ),

          // ── heart burst (double-tap) ──────────────────────────────────────
          if (_showHeart)
            Positioned(
              left: _heartPos.dx - 40,
              top: _heartPos.dy - 40,
              child: const _HeartBurst(),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _VideoBackground extends StatelessWidget {
  const _VideoBackground({required this.vpc, required this.short});

  final VideoPlayerController? vpc;
  final ShortEntity short;

  @override
  Widget build(BuildContext context) {
    final initialized = vpc?.value.isInitialized ?? false;
    return ColoredBox(
      color: Colors.black,
      child: initialized
          ? Center(
        child: AspectRatio(
          aspectRatio: vpc!.value.aspectRatio,
          child: VideoPlayer(vpc!),
        ),
      )
          : (short.thumbnail.isNotEmpty
          ? Image.network(
        short.thumbnail,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      )
          : const SizedBox.shrink()),
    );
  }
}

class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.45),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.88),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
            SizedBox(height: 10),
            Text(
              'Video unavailable',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _BufferingSpinner extends StatelessWidget {
  const _BufferingSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        color: Colors.white70,
        strokeWidth: 2.5,
      ),
    );
  }
}

// ── Centre Play/Pause ─────────────────────────────────────────────────────────
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.52),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}

// ── Bottom metadata ───────────────────────────────────────────────────────────
class _BottomMeta extends StatelessWidget {
  const _BottomMeta({
    required this.short,
    required this.position,
    required this.duration,
    required this.progress,
    required this.fmt,
    required this.showControls,
    required this.overlayFade,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    required this.onOpenDetail,
  });

  final ShortEntity short;
  final Duration position;
  final Duration duration;
  final double progress;
  final String Function(Duration) fmt;
  final bool showControls;
  final Animation<double> overlayFade;
  final void Function(double) onSeekStart;
  final void Function(double) onSeekUpdate;
  final Future<void> Function(double) onSeekEnd;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 14, right: 10, bottom: bottom + 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── author row ──────────────────────────────────────────────────
          _AuthorRow(short: short),
          const SizedBox(height: 8),

          // ── title ───────────────────────────────────────────────────────
          if (short.title.isNotEmpty)
            Text(
              short.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
                shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
              ),
            ),

          // ── description (1 line) ─────────────────────────────────────────
          if (short.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              short.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.3,
                shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── "View in Movie" pill button ──────────────────────────────────
          if (short.contentUrl.trim().isNotEmpty)
            _ViewInMovieButton(onTap: onOpenDetail),

          const SizedBox(height: 12),

          // ── seekbar ──────────────────────────────────────────────────────
          FadeTransition(
            opacity: overlayFade,
            child: showControls
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fmt(position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        fmt(duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                _SeekBar(
                  progress: progress,
                  onChangeStart: onSeekStart,
                  onChanged: onSeekUpdate,
                  onChangeEnd: onSeekEnd,
                ),
              ],
            )
                : _ThinProgressBar(progress: progress),
          ),
        ],
      ),
    );
  }
}

// ── Author row ────────────────────────────────────────────────────────────────
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.short});

  final ShortEntity short;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 1.5),
          ),
          child: ClipOval(
            child: short.authorAvatar.isNotEmpty
                ? Image.network(
              short.authorAvatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DefaultAvatar(),
            )
                : const _DefaultAvatar(),
          ),
        ),
        const SizedBox(width: 8),
        // name
        Flexible(
          child: Text(
            short.author.isNotEmpty ? short.author : 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white12,
      child: const Icon(Icons.person_rounded, color: Colors.white54, size: 20),
    );
  }
}

// ── "View in Movie" pill ──────────────────────────────────────────────────────
class _ViewInMovieButton extends StatelessWidget {
  const _ViewInMovieButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'View in Movie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Thin progress bar (always visible, no controls) ───────────────────────────
class _ThinProgressBar extends StatelessWidget {
  const _ThinProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 2.5,
        backgroundColor: Colors.white24,
        color: Colors.white,
      ),
    );
  }
}

// ── Full seekbar ──────────────────────────────────────────────────────────────
class _SeekBar extends StatelessWidget {
  const _SeekBar({
    required this.progress,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double progress;
  final void Function(double) onChangeStart;
  final void Function(double) onChanged;
  final Future<void> Function(double) onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white30,
        thumbColor: Colors.white,
        overlayColor: Colors.white24,
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChangeStart: onChangeStart,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

// ── Side rail ─────────────────────────────────────────────────────────────────
class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.short,
    required this.likeLoading,
    required this.onLike,
    required this.onOpenDetail,
  });

  final ShortEntity short;
  final bool likeLoading;
  final VoidCallback onLike;
  final VoidCallback onOpenDetail;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── like button ────────────────────────────────────────────────────
        _RailButton(
          onTap: onLike,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.elasticOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: likeLoading
                    ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  key: ValueKey(short.likedByMe),
                  short.likedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: short.likedByMe ? Colors.red : Colors.white,
                  size: 32,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
              ),
              if (short.likeCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _fmt(short.likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── views ──────────────────────────────────────────────────────────
        if (short.viewCount > 0)
          Column(
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                color: Colors.white,
                size: 26,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
              const SizedBox(height: 4),
              Text(
                _fmt(short.viewCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

        // ── open detail ────────────────────────────────────────────────────
        _OpenDetailButton(onTap: onOpenDetail),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: child,
      ),
    );
  }
}

class _OpenDetailButton extends StatelessWidget {
  const _OpenDetailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.movie_filter_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ── Heart burst animation (double-tap) ────────────────────────────────────────
class _HeartBurst extends StatefulWidget {
  const _HeartBurst();

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _ac,
    curve: const Interval(0, 0.5, curve: Curves.elasticOut),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _ac,
    curve: const Interval(0.5, 1, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) => Opacity(
        opacity: (1 - _fade.value).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: _scale.value * 1.9,
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF1744),
            size: 80,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
            ],
          ),
        ),
      ),
    );
  }
}