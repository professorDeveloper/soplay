# Shorts UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Shorts feature UI to YouTube Shorts/Instagram Reels quality, update API to cursor-based pagination, match all UI elements to actual API response fields.

**Architecture:** Data layer updated to match exact API response fields (remove unused fields, add `createdAt`, add `query` param for search). Bloc layer already cursor-based — verify and keep. UI fully rewritten: transparent AppBar, new gesture system (tap=play/pause, double-tap=like-only, long-press=2x speed), redesigned side rail, bottom meta with tags and pill button, smooth seekbar.

**Tech Stack:** Flutter, flutter_bloc, video_player, go_router, dio, hive_flutter, share_plus (new for share)

---

### Task 1: Update ShortEntity — remove unused fields, add createdAt

**Files:**
- Modify: `lib/features/shorts/domain/entities/short_entity.dart`

- [ ] **Step 1: Rewrite ShortEntity**

```dart
import 'package:equatable/equatable.dart';

class ShortEntity extends Equatable {
  const ShortEntity({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnail,
    required this.provider,
    required this.contentUrl,
    required this.contentTitle,
    required this.contentThumbnail,
    required this.likeCount,
    required this.viewCount,
    required this.likedByMe,
    required this.tags,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String videoUrl;
  final String thumbnail;
  final String provider;
  final String contentUrl;
  final String contentTitle;
  final String contentThumbnail;
  final int likeCount;
  final int viewCount;
  final bool likedByMe;
  final List<String> tags;
  final String createdAt;

  ShortEntity copyWith({
    String? id,
    String? title,
    String? videoUrl,
    String? thumbnail,
    String? provider,
    String? contentUrl,
    String? contentTitle,
    String? contentThumbnail,
    int? likeCount,
    int? viewCount,
    bool? likedByMe,
    List<String>? tags,
    String? createdAt,
  }) {
    return ShortEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      provider: provider ?? this.provider,
      contentUrl: contentUrl ?? this.contentUrl,
      contentTitle: contentTitle ?? this.contentTitle,
      contentThumbnail: contentThumbnail ?? this.contentThumbnail,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, title, videoUrl, thumbnail, provider, contentUrl,
        contentTitle, contentThumbnail, likeCount, viewCount,
        likedByMe, tags, createdAt,
      ];
}
```

Removed: `author`, `authorAvatar`, `description`. Added: `createdAt`.

- [ ] **Step 2: Verify no compile errors**

Run: `cd /Users/saikou/AndroidStudioProjects/soplay && flutter analyze lib/features/shorts/domain/entities/short_entity.dart`

This will show errors in files that reference removed fields — that's expected, fixed in next tasks.

---

### Task 2: Update ShortModel — simplify fromJson to match exact API

**Files:**
- Modify: `lib/features/shorts/data/models/short_model.dart`

- [ ] **Step 1: Rewrite ShortModel**

```dart
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';

class ShortModel extends ShortEntity {
  const ShortModel({
    required super.id,
    required super.title,
    required super.videoUrl,
    required super.thumbnail,
    required super.provider,
    required super.contentUrl,
    required super.contentTitle,
    required super.contentThumbnail,
    required super.likeCount,
    required super.viewCount,
    required super.likedByMe,
    required super.tags,
    required super.createdAt,
  });

  factory ShortModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.whereType<String>().toList()
        : const <String>[];

    return ShortModel(
      id: _str(json['_id']),
      title: _str(json['title']),
      videoUrl: _str(json['videoUrl']),
      thumbnail: _str(json['thumbnailUrl']),
      provider: _str(json['provider']),
      contentUrl: _str(json['contentUrl']),
      contentTitle: _str(json['contentTitle']),
      contentThumbnail: _str(json['contentThumbnail']),
      viewCount: _int(json['views']),
      likeCount: _int(json['likeCount']),
      likedByMe: _bool(json['likedByMe']),
      tags: tags,
      createdAt: _str(json['createdAt']),
    );
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    final raw = v?.toString().toLowerCase();
    return raw == 'true' || raw == '1';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/shorts/domain/entities/short_entity.dart lib/features/shorts/data/models/short_model.dart
git commit -m "refactor: update ShortEntity/ShortModel to match exact API response"
```

---

### Task 3: Update DataSource + Repository + UseCase — add query param

**Files:**
- Modify: `lib/features/shorts/data/datasources/shorts_remote_data_source.dart`
- Modify: `lib/features/shorts/domain/repositories/shorts_repository.dart`
- Modify: `lib/features/shorts/data/repositories/shorts_repository_impl.dart`
- Modify: `lib/features/shorts/domain/usecases/get_shorts_usecase.dart`

- [ ] **Step 1: Update ShortsRemoteDataSource — add query param**

In `shorts_remote_data_source.dart`, update `getShortsFeed`:

```dart
Future<ShortsFeedResult> getShortsFeed({
  String? cursor,
  String? query,
  int limit = 15,
}) async {
  final params = <String, dynamic>{'limit': limit};
  if (cursor != null) params['cursor'] = cursor;
  if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

  final response = await dio.get('/shorts/feed', queryParameters: params);
  final data = response.data;

  final rawItems = data is Map
      ? (data['items'] ?? const [])
      : (data is List ? data : const []);

  final items = (rawItems as List)
      .whereType<Map>()
      .map((e) => ShortModel.fromJson(e.cast<String, dynamic>()))
      .where((e) => e.id.isNotEmpty && e.videoUrl.isNotEmpty)
      .toList(growable: false);

  final nextCursor = data is Map ? (data['nextCursor'] as String?) : null;
  final hasMore = data is Map
      ? (data['hasMore'] as bool? ?? nextCursor != null)
      : false;

  return ShortsFeedResult(
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
  );
}
```

- [ ] **Step 2: Update ShortsRepository interface**

In `shorts_repository.dart`:

```dart
abstract class ShortsRepository {
  Future<Result<ShortsFeedResult>> getShortsFeed({
    String? cursor,
    String? query,
    int limit,
  });
  Future<Result<ShortEntity>> getShort(String id);
  Future<Result<void>> increaseView(String id);
  Future<Result<ShortLikeResult?>> toggleLike(String id);
}
```

- [ ] **Step 3: Update ShortsRepositoryImpl**

In `shorts_repository_impl.dart`, update `getShortsFeed`:

```dart
@override
Future<Result<ShortsFeedResult>> getShortsFeed({
  String? cursor,
  String? query,
  int limit = 15,
}) async {
  try {
    return Success(
      await dataSource.getShortsFeed(cursor: cursor, query: query, limit: limit),
    );
  } on DioException catch (e) {
    return Failure(Exception(_messageFrom(e)));
  } catch (e) {
    return Failure(Exception(e.toString()));
  }
}
```

- [ ] **Step 4: Update GetShortsUseCase**

In `get_shorts_usecase.dart`:

```dart
class GetShortsUseCase {
  const GetShortsUseCase(this.repository);

  final ShortsRepository repository;

  Future<Result<ShortsFeedResult>> call({
    String? cursor,
    String? query,
    int limit = 15,
  }) =>
      repository.getShortsFeed(cursor: cursor, query: query, limit: limit);
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/shorts/data/datasources/shorts_remote_data_source.dart \
  lib/features/shorts/domain/repositories/shorts_repository.dart \
  lib/features/shorts/data/repositories/shorts_repository_impl.dart \
  lib/features/shorts/domain/usecases/get_shorts_usecase.dart
git commit -m "feat: add query param to shorts feed API for search support"
```

---

### Task 4: Update ShortsBloc — fix references to removed entity fields

**Files:**
- Modify: `lib/features/shorts/presentation/bloc/shorts_bloc.dart`

- [ ] **Step 1: Verify ShortsBloc compiles**

The bloc already uses cursor-based pagination. The only change needed: the bloc references `ShortEntity` fields. Since we removed `author`, `authorAvatar`, `description` — verify the bloc doesn't reference them. The current bloc code does NOT reference those fields (it only uses `id`, `likedByMe`, `likeCount`, `copyWith`), so no changes needed.

Run: `flutter analyze lib/features/shorts/presentation/bloc/`

Expected: no errors in bloc files.

- [ ] **Step 2: Commit if any fixes were needed**

If no changes: skip commit. If fixes: commit with message `"fix: update shorts bloc for new entity fields"`.

---

### Task 5: Add share_plus dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add share_plus to pubspec.yaml**

Add under `dependencies:` section (after `floating`):

```yaml
  share_plus: ^10.1.4
```

- [ ] **Step 2: Install**

Run: `cd /Users/saikou/AndroidStudioProjects/soplay && flutter pub get`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add share_plus for shorts share feature"
```

---

### Task 6: Rewrite ShortReelItem — full UI redesign

**Files:**
- Modify: `lib/features/shorts/presentation/widgets/short_reel_item.dart`

This is the largest task. The file is a complete rewrite. The new widget handles:
- Video background with blur thumbnail while loading
- Tap = play/pause with animated center icon
- Double tap = like only (not unlike) with heart burst
- Long press = 2x speed with pill badge
- Side rail: like (toggle), views (display), share
- Bottom meta: provider, title, tags, pill button, seekbar

- [ ] **Step 1: Write the complete new ShortReelItem**

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _showControls = false;
  bool _speedBoosting = false;
  bool _seeking = false;
  double _seekValue = 0;
  bool _showHeart = false;
  Offset _heartPos = Offset.zero;

  late final AnimationController _playPauseAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _overlayAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _overlayFade = CurvedAnimation(
    parent: _overlayAnim,
    curve: Curves.easeInOut,
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
        _hideControlsNow();
        if (_speedBoosting) _stopSpeedBoost();
      } else {
        _vpc?.play();
      }
    }
  }

  @override
  void dispose() {
    _playPauseAnim.dispose();
    _overlayAnim.dispose();
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
      if (widget.active) c.play();
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

  // ── Tap = play/pause ──────────────────────────────────────
  void _onTap() {
    HapticFeedback.lightImpact();
    _isPlaying ? _vpc?.pause() : _vpc?.play();
    _showPlayPauseIcon();

    if (_showControls) {
      _scheduleHide();
    } else {
      _showControlsOverlay();
    }
  }

  void _showPlayPauseIcon() {
    setState(() => _showPlayPause = true);
    _playPauseAnim.forward(from: 0).then((_) {
      if (mounted) setState(() => _showPlayPause = false);
    });
  }

  void _showControlsOverlay() {
    setState(() => _showControls = true);
    _overlayAnim.forward();
    _scheduleHide();
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

  // ── Double tap = like only ────────────────────────────────
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

  // ── Long press = 2x speed ────────────────────────────────
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

  // ── Seek ──────────────────────────────────────────────────
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

  // ── Share ─────────────────────────────────────────────────
  void _onShare() {
    final title = widget.short.title;
    SharePlus.instance.share(
      ShareParams(text: title.isNotEmpty ? title : 'Check out this short!'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
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
          _buildTopScrim(),
          _buildBottomScrim(),
          if (_hasError) _buildErrorOverlay(),
          if (!_hasError && (!_initialized || _isBuffering))
            const Center(child: _BufferingSpinner()),
          if (_showPlayPause) _buildPlayPauseCenter(),
          if (_speedBoosting) _buildSpeedBadge(),
          Positioned(
            right: 12,
            bottom: bottom + 140,
            child: _buildSideRail(),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: bottom + 10,
            child: _buildBottomMeta(),
          ),
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

  Widget _buildVideoBackground() {
    if (_hasError) return const ColoredBox(color: Colors.black);
    if (_initialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _vpc!.value.aspectRatio,
            child: VideoPlayer(_vpc!),
          ),
        ),
      );
    }
    final thumb = widget.short.thumbnail;
    if (thumb.isEmpty) return const ColoredBox(color: Colors.black);
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Colors.black),
          ),
        ),
        ColoredBox(color: Colors.black.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildTopScrim() {
    return Positioned(
      left: 0, right: 0, top: 0, height: 100,
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

  Widget _buildBottomScrim() {
    return Positioned(
      left: 0, right: 0, bottom: 0, height: 320,
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

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
            SizedBox(height: 10),
            Text('Video unavailable',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseCenter() {
    return Center(
      child: AnimatedBuilder(
        animation: _playPauseAnim,
        builder: (_, __) {
          final scale = Curves.elasticOut
              .transform((_playPauseAnim.value * 2).clamp(0.0, 1.0));
          final opacity =
              _playPauseAnim.value < 0.5 ? 1.0 : (1.0 - ((_playPauseAnim.value - 0.5) * 2)).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 0.5 + scale * 0.5,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.52),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
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
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _speedBoosting ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fast_forward_rounded, color: Colors.white, size: 16),
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
    );
  }

  Widget _buildSideRail() {
    final s = widget.short;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (s.viewCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                const Icon(Icons.remove_red_eye_outlined, color: Colors.white,
                    size: 22, shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
                const SizedBox(height: 3),
                Text(_fmtCount(s.viewCount),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)])),
              ],
            ),
          ),
        _RailButton(
          onTap: _onShare,
          child: const Icon(Icons.share_rounded, color: Colors.white, size: 24,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
        ),
      ],
    );
  }

  Widget _buildBottomMeta() {
    final s = widget.short;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.provider.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 62),
            child: Text(s.provider,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 4)])),
          ),
        if (s.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 62),
            child: Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w600, height: 1.35,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 6)])),
          ),
        if (s.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 62),
            child: Row(
              children: s.tags.take(3).map((tag) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('#$tag',
                      style: const TextStyle(color: Colors.white70,
                          fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              )).toList(),
            ),
          ),
        if (s.contentTitle.isNotEmpty) _buildPillButton(s),
        const SizedBox(height: 10),
        if (_showControls)
          FadeTransition(
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
                          style: const TextStyle(color: Colors.white70,
                              fontSize: 11, fontWeight: FontWeight.w500)),
                      Text(_fmt(_duration),
                          style: const TextStyle(color: Colors.white70,
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                SliderTheme(
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
                    value: (_seeking ? _seekValue : _progress).clamp(0.0, 1.0),
                    onChangeStart: _onSeekStart,
                    onChanged: _onSeekUpdate,
                    onChangeEnd: _onSeekEnd,
                  ),
                ),
              ],
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 2.5,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildPillButton(ShortEntity s) {
    return Center(
      child: GestureDetector(
        onTap: widget.onOpenDetail,
        child: Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 26),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (s.contentThumbnail.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(s.contentThumbnail,
                      width: 28, height: 28, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.movie_rounded, color: Colors.white70, size: 20)),
                )
              else
                const Icon(Icons.movie_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.contentTitle, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              const Text('Watch', style: TextStyle(color: Colors.white70,
                  fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white70, size: 16),
            ],
          ),
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
      width: 40, height: 40,
      child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
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
    vsync: this, duration: const Duration(milliseconds: 850),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _ac, curve: const Interval(0, 0.5, curve: Curves.elasticOut),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ac, curve: const Interval(0.5, 1, curve: Curves.easeIn),
  );

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) => Opacity(
        opacity: (1 - _fade.value).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: _scale.value * 1.9,
          child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF1744),
              size: 80, shadows: [
                Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
              ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify build**

Run: `flutter analyze lib/features/shorts/presentation/widgets/short_reel_item.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/features/shorts/presentation/widgets/short_reel_item.dart
git commit -m "feat: rewrite ShortReelItem with new gestures, side rail, and bottom meta"
```

---

### Task 7: Update ShortsPage — add transparent AppBar + load more indicator

**Files:**
- Modify: `lib/features/shorts/presentation/pages/shorts_page.dart`

- [ ] **Step 1: Rewrite ShortsPage**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_bloc.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_event.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_state.dart';
import 'package:soplay/features/shorts/presentation/widgets/short_reel_item.dart';
import 'package:soplay/features/shorts/presentation/widgets/shorts_state_views.dart';

class ShortsPage extends StatelessWidget {
  const ShortsPage({
    super.key,
    required this.active,
    required this.refreshTick,
  });

  final bool active;
  final int refreshTick;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShortsBloc>()..add(const ShortsLoad()),
      child: _ShortsView(active: active, refreshTick: refreshTick),
    );
  }
}

class _ShortsView extends StatefulWidget {
  const _ShortsView({required this.active, required this.refreshTick});
  final bool active;
  final int refreshTick;

  @override
  State<_ShortsView> createState() => _ShortsViewState();
}

class _ShortsViewState extends State<_ShortsView>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final PageController _controller = PageController();
  bool _appActive = true;
  bool _detailOpen = false;

  @override
  bool get wantKeepAlive => true;

  bool get _playbackActive => widget.active && _appActive && !_detailOpen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant _ShortsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final next = state == AppLifecycleState.resumed;
    if (_appActive == next) return;
    setState(() => _appActive = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<ShortsBloc>().add(const ShortsRefresh());
    if (_controller.hasClients) {
      _controller.animateToPage(0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _openDetail(ShortEntity short) async {
    final contentUrl = short.contentUrl.trim();
    if (contentUrl.isEmpty) {
      _showNotice('Detail is not available');
      return;
    }
    setState(() => _detailOpen = true);
    final provider = short.provider.trim();
    if (provider.isNotEmpty) {
      await getIt<HiveService>().saveCurrentProvider(provider);
    }
    if (!mounted) return;
    await context.push('/detail', extra: DetailArgs(contentUrl: contentUrl));
    if (mounted) setState(() => _detailOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ShortsBloc, ShortsState>(
        listenWhen: (previous, current) {
          return previous is ShortsLoaded &&
              current is ShortsLoaded &&
              previous.noticeId != current.noticeId &&
              current.notice != null;
        },
        listener: (context, state) {
          if (state is ShortsLoaded && state.notice != null) {
            _showNotice(state.notice!);
          }
        },
        builder: (context, state) {
          return switch (state) {
            ShortsInitial() || ShortsLoading() => const ShortsLoadingView(),
            ShortsError(:final message) => ShortsErrorView(
                message: message,
                onRetry: () =>
                    context.read<ShortsBloc>().add(const ShortsLoad())),
            ShortsLoaded(:final items) => items.isEmpty
                ? const ShortsEmptyView()
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _controller,
                        scrollDirection: Axis.vertical,
                        itemCount:
                            items.length + (state.loadingMore ? 1 : 0),
                        onPageChanged: (index) {
                          if (index < items.length) {
                            context
                                .read<ShortsBloc>()
                                .add(ShortsPageChanged(index));
                          }
                        },
                        itemBuilder: (context, index) {
                          if (index >= items.length) {
                            return const ColoredBox(
                              color: Colors.black,
                              child: Center(
                                child: SizedBox(
                                  width: 32, height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white70,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            );
                          }
                          final item = items[index];
                          return ShortReelItem(
                            short: item,
                            active: _playbackActive &&
                                state.activeIndex == index,
                            likeLoading:
                                state.loadingLikeIds.contains(item.id),
                            onLike: () => context
                                .read<ShortsBloc>()
                                .add(ShortsLikeToggled(item.id)),
                            onOpenDetail: () => _openDetail(item),
                          );
                        },
                      ),
                      // Transparent AppBar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: topPad + 12, left: 16, right: 16),
                          child: Text(
                            'navigation.shorts'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                    color: Colors.black87,
                                    blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (state.refreshing)
                        Positioned(
                          top: topPad,
                          left: 0,
                          right: 0,
                          child: const LinearProgressIndicator(
                            minHeight: 2,
                            color: AppColors.primary,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
          };
        },
      ),
    );
  }
}
```

Key changes:
- Added transparent "Shorts" text at top with safe area
- `itemCount` includes +1 when `loadingMore` — shows spinner on last page
- Load more spinner page: black bg + small centered spinner
- Removed `hide ShortEntity` import hack

- [ ] **Step 2: Verify build**

Run: `flutter analyze lib/features/shorts/presentation/pages/shorts_page.dart`

- [ ] **Step 3: Commit**

```bash
git add lib/features/shorts/presentation/pages/shorts_page.dart
git commit -m "feat: add transparent AppBar and load more indicator to ShortsPage"
```

---

### Task 8: Full build verification and fix compile errors

**Files:**
- Potentially any file referencing removed `ShortEntity` fields

- [ ] **Step 1: Run full analysis**

Run: `cd /Users/saikou/AndroidStudioProjects/soplay && flutter analyze`

- [ ] **Step 2: Fix any compile errors**

Common errors expected:
- References to `short.author`, `short.authorAvatar`, `short.description` in any file — remove those references
- Import path issues — fix as needed

- [ ] **Step 3: Verify clean analysis**

Run: `flutter analyze`

Expected: No errors (warnings are OK).

- [ ] **Step 4: Commit fixes**

```bash
git add -A
git commit -m "fix: resolve compile errors from entity field changes"
```

---

### Task 9: Test on device/emulator

- [ ] **Step 1: Run the app**

Run: `flutter run`

- [ ] **Step 2: Manual verification checklist**

Verify each interaction:
1. Shorts tab opens, "Shorts" text visible at top
2. Video plays automatically
3. Single tap pauses/plays with center icon animation
4. Double tap shows heart burst and likes (first time)
5. Double tap when already liked shows heart only, no API call
6. Long press shows "2x speed" badge, video speeds up, release returns to 1x
7. Side rail: like toggle works, views display, share opens share sheet
8. Bottom: provider name, title, tags visible
9. Pill button shows contentThumbnail + contentTitle + "Watch", opens detail
10. Thin progress bar visible, tap shows full seekbar
11. Scroll to near end triggers load more (spinner visible)
12. Load more appends new items seamlessly

- [ ] **Step 3: Commit any fixes from testing**

```bash
git add -A
git commit -m "fix: polish shorts UI from device testing"
```
