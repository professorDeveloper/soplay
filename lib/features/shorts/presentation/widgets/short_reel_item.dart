import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/short_entity.dart';

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
    with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  bool _hasError = false;
  bool _showPlayPause = false;
  bool _lastIconWasPause = false;
  bool _showControls = false;
  bool _speedBoosting = false;
  bool _seeking = false;
  double _seekValue = 0;
  bool _showHeart = false;
  Offset _heartPos = Offset.zero;
  bool _muted = false;

  late final AnimationController _playPauseAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final AnimationController _overlayAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _overlayFade = CurvedAnimation(
    parent: _overlayAnim,
    curve: Curves.easeInOut,
  );

  late final AnimationController _discAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

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
        _discAnim.stop();
        _hideControlsNow();
        if (_speedBoosting) _stopSpeedBoost();
      } else {
        _vpc?.play();
        _discAnim.repeat();
      }
    }
  }

  @override
  void dispose() {
    _playPauseAnim.dispose();
    _overlayAnim.dispose();
    _discAnim.dispose();
    _vpc?.removeListener(_onTick);
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
      c.addListener(_onTick);
      if (widget.active) {
        c.play();
        _discAnim.repeat();
      }
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  bool get _isPlaying => _vpc?.value.isPlaying ?? false;
  bool get _initialized => _vpc?.value.isInitialized ?? false;
  bool get _isBuffering => _vpc?.value.isBuffering ?? false;
  Duration get _position => _vpc?.value.position ?? Duration.zero;
  Duration get _duration => _vpc?.value.duration ?? Duration.zero;

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

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _vpc?.pause();
      _discAnim.stop();
      _lastIconWasPause = true;
    } else {
      _vpc?.play();
      _discAnim.repeat();
      _lastIconWasPause = false;
    }
    _showPlayPauseIcon();
  }

  void _showPlayPauseIcon() {
    setState(() => _showPlayPause = true);
    _playPauseAnim.forward(from: 0).then((_) {
      if (mounted) setState(() => _showPlayPause = false);
    });
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

  void _onDoubleTapDown(TapDownDetails d) {
    HapticFeedback.mediumImpact();
    if (!widget.short.likedByMe) {
      widget.onLike();
    }
    setState(() {
      _heartPos = d.localPosition;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _onLongPressStart(LongPressStartDetails _) {
    final c = _vpc;
    if (c == null || !c.value.isInitialized || !c.value.isPlaying) return;
    HapticFeedback.lightImpact();
    c.setPlaybackSpeed(2.0);
    setState(() => _speedBoosting = true);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _stopSpeedBoost();
  }

  void _stopSpeedBoost() {
    if (!_speedBoosting) return;
    _vpc?.setPlaybackSpeed(1.0);
    if (mounted) setState(() => _speedBoosting = false);
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

  void _toggleMute() {
    HapticFeedback.lightImpact();
    setState(() => _muted = !_muted);
    _vpc?.setVolume(_muted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onDoubleTapDown: _onDoubleTapDown,
          onDoubleTap: () {},
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildVideoBackground(),
              _buildBottomScrim(),
              if (_hasError) _buildErrorOverlay(),
              if (!_hasError && (!_initialized || _isBuffering))
                const Center(child: _BufferingSpinner()),
            ],
          ),
        ),
        if (_showPlayPause) _buildPlayPauseCenter(),
        if (_speedBoosting) _buildSpeedBadge(),
        Positioned(
          right: 12,
          bottom: bottom + 100,
          child: _buildSideRail(),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: bottom + 12,
          child: _buildBottomSection(),
        ),
        if (_showHeart)
          Positioned(
            left: _heartPos.dx - 40,
            top: _heartPos.dy - 40,
            child: const _HeartBurst(),
          ),
      ],
    );
  }

  Widget _buildVideoBackground() {
    if (_hasError) {
      return const SizedBox.expand(child: ColoredBox(color: Colors.black));
    }
    if (_initialized) {
      return SizedBox.expand(
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: _vpc!.value.aspectRatio,
              child: VideoPlayer(_vpc!),
            ),
          ),
        ),
      );
    }
    final thumb = widget.short.thumbnail;
    if (thumb.isEmpty) {
      return const SizedBox.expand(child: ColoredBox(color: Colors.black));
    }
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Image.network(
              thumb,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) =>
                  const ColoredBox(color: Colors.black),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildBottomScrim() {
    return Positioned(
      left: 0, right: 0, bottom: 0, height: 350,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48),
              SizedBox(height: 10),
              Text('Video unavailable',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseCenter() {
    return Center(
      child: AnimatedBuilder(
        animation: _playPauseAnim,
        builder: (_, child) {
          final t = _playPauseAnim.value;
          final scale = t < 0.3
              ? Curves.elasticOut.transform((t / 0.3).clamp(0.0, 1.0))
              : 1.0;
          final opacity =
              t < 0.5 ? 1.0 : (1.0 - ((t - 0.5) * 2)).clamp(0.0, 1.0);
          return IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.5 + scale * 0.5,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _lastIconWasPause
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeedBadge() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 50,
      left: 0, right: 0,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (_, value, child) => Transform.scale(
              scale: 0.8 + value * 0.2,
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fast_forward_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('2x speed',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideRail() {
    final s = widget.short;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _RailButton(
          onTap: widget.onLike,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.elasticOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: widget.likeLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        key: ValueKey(s.likedByMe),
                        s.likedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: s.likedByMe ? Colors.red : Colors.white,
                        size: 28,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6)
                        ],
                      ),
              ),
              if (s.likeCount > 0) ...[
                const SizedBox(height: 3),
                Text(_fmtCount(s.likeCount),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 3)
                        ])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Views
        if (s.viewCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                const Icon(Icons.remove_red_eye_outlined,
                    color: Colors.white, size: 22,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
                const SizedBox(height: 3),
                Text(_fmtCount(s.viewCount),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 3)
                        ])),
              ],
            ),
          ),

        // Mute/unmute
        _RailButton(
          onTap: _toggleMute,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white, size: 18,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Spinning disc (content thumbnail)
        if (s.contentThumbnail.isNotEmpty)
          _buildSpinningDisc(s),
      ],
    );
  }

  Widget _buildSpinningDisc(ShortEntity s) {
    return GestureDetector(
      onTap: widget.onOpenDetail,
      child: AnimatedBuilder(
        animation: _discAnim,
        builder: (_, child) => Transform.rotate(
          angle: _discAnim.value * 6.283,
          child: child,
        ),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  s.contentThumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Icon(Icons.movie_rounded,
                        color: Colors.white54, size: 22),
                  ),
                ),
                Center(
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
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

  Widget _buildBottomSection() {
    final s = widget.short;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.provider.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (s.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    s.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 6)
                      ],
                    ),
                  ),
                ),
              if (s.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: s.tags
                        .take(3)
                        .map((tag) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        if (s.contentTitle.isNotEmpty ||
            s.contentUrl.trim().isNotEmpty ||
            s.tags.isNotEmpty)
          _buildPillButton(s),
        const SizedBox(height: 10),
        _buildSeekSection(),
      ],
    );
  }

  Widget _buildPillButton(ShortEntity s) {
    return Center(
      child: GestureDetector(
        onTap: widget.onOpenDetail,
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.only(left: 4, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: s.contentThumbnail.isNotEmpty
                    ? Image.network(
                        s.contentThumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => const Center(
                          child: Icon(Icons.movie_rounded,
                              color: Colors.white70, size: 20),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.movie_rounded,
                            color: Colors.white70, size: 20),
                      ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.contentTitle.isNotEmpty
                          ? s.contentTitle
                          : s.tags.isNotEmpty
                              ? s.tags.first[0].toUpperCase() +
                                  s.tags.first.substring(1)
                              : 'Movies',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      s.contentUrl.trim().isNotEmpty
                          ? 'Watch Full Movie'
                          : 'Browse Movies',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeekSection() {
    if (_showControls) {
      return FadeTransition(
        opacity: _overlayFade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  Text(_fmt(_duration),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 20,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                ),
                child: Slider(
                  value:
                      (_seeking ? _seekValue : _progress).clamp(0.0, 1.0),
                  onChangeStart: _onSeekStart,
                  onChanged: _onSeekUpdate,
                  onChangeEnd: _onSeekEnd,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: _progress,
          minHeight: 3,
          backgroundColor: Colors.white24,
          color: const Color(0xFFE53935),
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
      width: 36, height: 36,
      child:
          CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
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
      builder: (_, child) => Opacity(
        opacity: (1 - _fade.value).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: _scale.value * 1.9,
          child: const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF1744),
            size: 80,
            shadows: [
              Shadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 4)),
            ],
          ),
        ),
      ),
    );
  }
}
