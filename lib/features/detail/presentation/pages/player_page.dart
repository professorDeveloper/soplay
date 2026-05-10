import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/episode_entity.dart';
import 'package:soplay/features/detail/domain/entities/player_args.dart';
import 'package:soplay/features/detail/domain/entities/subtitle_entity.dart';
import 'package:soplay/features/detail/domain/entities/video_source_entity.dart';
import 'package:soplay/features/detail/domain/usecases/resolve_media_usecase.dart';
import 'package:soplay/features/download/data/download_service.dart';
import 'package:soplay/features/download/domain/entities/download_item.dart';
import 'package:soplay/features/history/data/history_service.dart';
import 'package:soplay/features/history/domain/entities/history_item.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum _PlayerFit { contain, cover, fill }

enum _SidePanel { none, episodes, quality }

enum _LoadingStage { resolving, loading }

enum _SwipeType { brightness, volume }

class _SwipeIndicator {
  final _SwipeType type;
  final double value;
  const _SwipeIndicator(this.type, this.value);
}

const _kSubLang = 'sub';
const _kDubLang = 'dub';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.args});
  final PlayerArgs args;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const MethodChannel _pipChannel = MethodChannel('soplay/pip');
  static const MethodChannel _systemControlsChannel = MethodChannel(
    'soplay/system_controls',
  );

  final ResolveMediaUseCase _resolve = getIt<ResolveMediaUseCase>();
  final HiveService _hive = getIt<HiveService>();
  final HistoryService _history = getIt<HistoryService>();
  final DownloadService _downloads = getIt<DownloadService>();
  final Floating _floating = Floating();
  bool _isPip = false;
  bool _resumeAfterPause = false;
  bool _lastPipPlaying = false;

  VideoPlayerController? _controller;
  late int _episodeIndex;
  String? _currentQuality;
  String? _videoUrl;
  String? _mediaType;
  Map<String, String> _headers = const {};
  List<VideoSourceEntity> _videoSources = const [];
  int _currentSourceIndex = -1;
  bool _autoFallbackUsed = false;
  String? _errorMessage;
  bool _initializing = true;
  _LoadingStage _stage = _LoadingStage.loading;
  bool _controlsVisible = true;
  bool _locked = false;
  _SidePanel _panel = _SidePanel.none;

  String? _currentLang;
  List<String> _serverLangs = const [];

  List<SubtitleEntity> _subtitles = const [];
  int _activeSubtitleIndex = -1;
  ClosedCaptionFile? _captionFile;

  double _playbackSpeed = 1.0;
  _PlayerFit _fit = _PlayerFit.contain;
  bool _isPortrait = false;

  double _brightness = 0.5;
  double _volume = 1.0;
  final ValueNotifier<_SwipeIndicator?> _swipeIndicator =
      ValueNotifier<_SwipeIndicator?>(null);

  Offset? _dragStart;
  bool? _dragIsHorizontal;
  _SwipeType? _dragSwipeType;

  final ValueNotifier<_ScrubState?> _scrub = ValueNotifier<_ScrubState?>(null);
  final ValueNotifier<bool> _speedBoost = ValueNotifier<bool>(false);
  double? _speedBeforeBoost;

  Timer? _hideTimer;
  Timer? _historyTimer;
  late final AnimationController _controlsAnimation;

  late final AnimationController _seekRippleController;
  Timer? _seekRippleTimer;
  int _seekRippleDirection = 0;
  int _seekRippleSeconds = 0;

  int _retryAttempts = 0;
  bool _autoRetrying = false;
  final Stopwatch _playbackWatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _episodeIndex = widget.args.initialEpisodeIndex.clamp(
      0,
      widget.args.episodes.isEmpty ? 0 : widget.args.episodes.length - 1,
    );
    _currentLang = widget.args.initialLang ?? _hive.getPreferredMediaLang();
    _controlsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _seekRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addObserver(this);
    _pipChannel.setMethodCallHandler(_onPipMethodCall);
    unawaited(_loadSystemControlValues());
    _startup();
  }

  Future<void> _loadSystemControlValues() async {
    try {
      final results = await Future.wait([
        _systemControlsChannel.invokeMethod<double>('getBrightness'),
        _systemControlsChannel.invokeMethod<double>('getVolume'),
      ]);
      _brightness = (results[0] ?? _brightness).clamp(0.0, 1.0).toDouble();
      _volume = (results[1] ?? _volume).clamp(0.0, 1.0).toDouble();
    } catch (_) {}
  }

  Future<void> _onPipMethodCall(MethodCall call) async {
    if (call.method != 'onPipAction') return;
    final action = call.arguments;
    if (action is! String) return;
    switch (action) {
      case 'play_pause':
        _togglePlay();
        _refreshPipActions();
      case 'rewind':
        _seekRelative(const Duration(seconds: -10));
      case 'forward':
        _seekRelative(const Duration(seconds: 10));
      case 'prev':
        if (widget.args.isSerial && _episodeIndex - 1 >= 0) {
          _loadEpisode(_episodeIndex - 1);
        }
      case 'next':
        if (widget.args.isSerial &&
            _episodeIndex + 1 < widget.args.episodes.length) {
          _loadEpisode(_episodeIndex + 1);
        }
    }
  }

  Future<void> _refreshPipActions() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final isPlaying = c.value.isPlaying;
    final hasPrev = widget.args.isSerial && _episodeIndex > 0;
    final hasNext =
        widget.args.isSerial && _episodeIndex + 1 < widget.args.episodes.length;
    if (isPlaying == _lastPipPlaying) {
      try {
        await _pipChannel.invokeMethod('updatePiPActions', {
          'isPlaying': isPlaying,
          'hasPrev': hasPrev,
          'hasNext': hasNext,
        });
      } catch (_) {}
      return;
    }
    _lastPipPlaying = isPlaying;
    try {
      await _pipChannel.invokeMethod('updatePiPActions', {
        'isPlaying': isPlaying,
        'hasPrev': hasPrev,
        'hasNext': hasNext,
      });
    } catch (_) {}
  }

  Future<void> _enterPip() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      final available = await _floating.isPipAvailable;
      if (!available) return;
      final size = c.value.size;
      Rational ratio = const Rational.landscape();
      if (size.width > 0 && size.height > 0) {
        final w = size.width.round();
        final h = size.height.round();
        if (w > 0 && h > 0) {
          final candidate = Rational(w, h);
          final aspect = candidate.aspectRatio;
          if (aspect >= 1 / 2.39 && aspect <= 2.39) {
            ratio = candidate;
          }
        }
      }
      final result = await _floating.enable(ImmediatePiP(aspectRatio: ratio));
      if (result == PiPStatus.enabled && mounted) {
        setState(() {
          _isPip = true;
          _controlsVisible = false;
          _hideTimer?.cancel();
          _panel = _SidePanel.none;
        });
        _controlsAnimation.reverse();
        _lastPipPlaying = !c.value.isPlaying;
        _refreshPipActions();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (c.value.isInitialized && c.value.isPlaying && !_isPip) {
          _resumeAfterPause = true;
          c.pause();
        }
        break;
      case AppLifecycleState.resumed:
        if (_isPip && mounted) {
          setState(() => _isPip = false);
        }
        if (_resumeAfterPause && c.value.isInitialized) {
          c.play();
        }
        _resumeAfterPause = false;
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _startup() async {
    final sw = Stopwatch()..start();
    debugPrint('[PLAYER] startup — entering fullscreen');
    await _enterFullscreen();
    debugPrint('[PLAYER] fullscreen ready in ${sw.elapsedMilliseconds}ms');
    if (!mounted) return;
    await _bootstrap();
  }

  String? _defaultRefererFor(String provider) {
    switch (provider.toLowerCase()) {
      case 'asilmedia':
        return 'https://asilmedia.org/';
      default:
        return null;
    }
  }

  bool _isHlsType(String? type) => type?.trim().toLowerCase() == 'hls';

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}
    await WakelockPlus.enable();
  }

  Future<void> _toggleOrientation() async {
    _isPortrait = !_isPortrait;
    try {
      if (_isPortrait) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (_) {}
    setState(() {});
  }

  Future<void> _restoreSystemUi() async {
    _isPortrait = false;
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (_) {}
    await WakelockPlus.disable();
  }

  Future<void> _bootstrap() async {
    final resume = widget.args.resumePosition;
    if (widget.args.isSerial) {
      await _loadEpisode(_episodeIndex, resumeAt: resume);
    } else {
      _videoSources = List.of(widget.args.videoSources);
      _currentSourceIndex = _pickInitialMovieSourceIndex(_videoSources);
      _autoFallbackUsed = false;
      final source = _currentSourceIndex >= 0
          ? _videoSources[_currentSourceIndex]
          : null;
      _currentQuality = source?.quality;
      if (mounted) setState(() => _stage = _LoadingStage.loading);
      await _initializeWith(
        url: source?.videoUrl ?? widget.args.movieUrl ?? '',
        headers: widget.args.headers,
        type: widget.args.type,
        resumeAt: resume,
      );
    }
  }

  int _pickInitialMovieSourceIndex(List<VideoSourceEntity> sources) {
    if (sources.isEmpty) return -1;
    for (var i = 0; i < sources.length; i++) {
      if (sources[i].isDefault && sources[i].accessible) return i;
    }
    for (var i = 0; i < sources.length; i++) {
      if (sources[i].accessible) return i;
    }
    return 0;
  }

  Future<void> _loadEpisode(
    int index, {
    Duration resumeAt = Duration.zero,
    bool keepRetryCount = false,
  }) async {
    if (index < 0 || index >= widget.args.episodes.length) return;
    if (!keepRetryCount) _retryAttempts = 0;
    setState(() {
      _initializing = true;
      _stage = _LoadingStage.resolving;
      _errorMessage = null;
      _episodeIndex = index;
      _panel = _SidePanel.none;
    });
    await _disposeController();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final ep = widget.args.episodes[index];
    if (ep.mediaRef.isEmpty) {
      setState(() {
        _initializing = false;
        _errorMessage = 'No source for this episode';
      });
      return;
    }

    final lang = _resolveLangForEpisode(ep);

    final resolveSw = Stopwatch()..start();
    debugPrint('[PLAYER] resolving ref=${ep.mediaRef} lang=$lang');
    final result = await _resolve(
      ref: ep.mediaRef,
      provider: widget.args.provider,
      lang: lang,
    );
    debugPrint(
      '[PLAYER] resolve completed in ${resolveSw.elapsedMilliseconds}ms',
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        final sources = value.videoSources;
        final useSources = sources.isNotEmpty;
        final pickedIdx = useSources ? 0 : -1;
        final url = useSources ? sources[pickedIdx].videoUrl : value.videoUrl;
        final subs = value.subtitles;
        setState(() {
          _stage = _LoadingStage.loading;
          _serverLangs = value.languagesAvailable;
          _currentLang = value.activeLang ?? lang ?? _currentLang;
          _videoSources = useSources ? List.of(sources) : const [];
          _currentSourceIndex = pickedIdx;
          _currentQuality = useSources ? sources[pickedIdx].quality : null;
          _autoFallbackUsed = false;
          _subtitles = subs;
          _activeSubtitleIndex = -1;
          _captionFile = null;
        });
        await _initializeWith(
          url: url,
          headers: value.headers,
          type: value.type,
          resumeAt: resumeAt,
        );
        if (subs.isNotEmpty) {
          final defaultIdx = subs.indexWhere((s) => s.isDefault);
          if (defaultIdx >= 0) {
            _loadSubtitle(defaultIdx);
          }
        }
      case Failure(:final error):
        setState(() {
          _initializing = false;
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  String? _resolveLangForEpisode(EpisodeEntity ep) {
    final epLangs = ep.availableLangs;
    if (epLangs.isEmpty) return null;
    final saved = _currentLang;
    if (saved != null && epLangs.contains(saved)) return saved;
    if (epLangs.contains(_kSubLang)) return _kSubLang;
    return epLangs.first;
  }

  void _scheduleHistorySave() {
    _historyTimer?.cancel();
    _historyTimer = Timer(const Duration(seconds: 5), _saveHistory);
  }

  void _saveHistory() {
    if (_playbackWatch.elapsed.inSeconds < 30) return;

    final contentUrl = widget.args.contentUrl;
    if (contentUrl == null || contentUrl.isEmpty) return;
    final c = _controller;
    final posMs = c != null && c.value.isInitialized
        ? c.value.position.inMilliseconds
        : 0;
    final durMs = c != null && c.value.isInitialized
        ? c.value.duration.inMilliseconds
        : 0;

    if (durMs > 0 && posMs >= durMs - 2000) return;

    EpisodeEntity? ep;
    if (widget.args.isSerial &&
        _episodeIndex >= 0 &&
        _episodeIndex < widget.args.episodes.length) {
      ep = widget.args.episodes[_episodeIndex];
    }

    _history.save(
      HistoryItem(
        contentUrl: contentUrl,
        provider: widget.args.provider,
        title: widget.args.title,
        thumbnail: widget.args.thumbnail,
        isSerial: widget.args.isSerial,
        episodeIndex: widget.args.isSerial ? _episodeIndex : null,
        episodeNumber: ep?.episode,
        episodeLabel: ep?.label,
        positionMs: posMs,
        durationMs: durMs,
        watchedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _saveHistoryForNextEpisode() {
    final contentUrl = widget.args.contentUrl;
    if (contentUrl == null || contentUrl.isEmpty) return;
    if (!widget.args.isSerial) return;

    final nextIdx = _episodeIndex + 1;
    if (nextIdx >= widget.args.episodes.length) return;

    final nextEp = widget.args.episodes[nextIdx];
    _history.save(
      HistoryItem(
        contentUrl: contentUrl,
        provider: widget.args.provider,
        title: widget.args.title,
        thumbnail: widget.args.thumbnail,
        isSerial: true,
        episodeIndex: nextIdx,
        episodeNumber: nextEp.episode,
        episodeLabel: nextEp.label,
        positionMs: 0,
        durationMs: 0,
        watchedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  List<String> _availableLangsForCurrentEpisode() {
    if (!widget.args.isSerial) return const [];
    if (_episodeIndex < 0 || _episodeIndex >= widget.args.episodes.length) {
      return const [];
    }
    final epLangs = widget.args.episodes[_episodeIndex].availableLangs;
    if (epLangs.isNotEmpty) return epLangs;
    return _serverLangs;
  }

  Future<void> _switchLang(String lang) async {
    if (!widget.args.isSerial) return;
    if (lang == _currentLang) return;
    final keepPosition = _controller?.value.position ?? Duration.zero;
    setState(() => _currentLang = lang);
    await _hive.savePreferredMediaLang(lang);
    await _loadEpisode(_episodeIndex, resumeAt: keepPosition);
  }

  Future<void> _switchQuality(VideoSourceEntity source) async {
    if (source.quality == _currentQuality) {
      setState(() => _panel = _SidePanel.none);
      return;
    }
    final keepPosition = _controller?.value.position ?? Duration.zero;
    final idx = _videoSources.indexWhere((s) => s.quality == source.quality);
    _retryAttempts = 0;
    setState(() {
      _initializing = true;
      _stage = _LoadingStage.loading;
      _errorMessage = null;
      _currentQuality = source.quality;
      _currentSourceIndex = idx >= 0 ? idx : _currentSourceIndex;
      _autoFallbackUsed = false;
      _panel = _SidePanel.none;
    });
    await _disposeController();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _initializeWith(
      url: source.videoUrl,
      headers: _headers.isNotEmpty ? _headers : widget.args.headers,
      type: _mediaType,
      resumeAt: keepPosition,
    );
  }

  Future<void> _initializeWith({
    required String url,
    required Map<String, String> headers,
    required String? type,
    Duration resumeAt = Duration.zero,
  }) async {
    if (url.isEmpty) {
      setState(() {
        _initializing = false;
        _errorMessage = 'Empty video URL';
      });
      return;
    }

    final stopwatch = Stopwatch()..start();
    final isFileUri = url.startsWith('file://');
    final isLocal = url.startsWith('/') || isFileUri;
    final isHls = _isHlsType(type);

    debugPrint('[PLAYER] loading url: $url');
    debugPrint('[PLAYER] type: ${type ?? 'unknown'} local: $isLocal');

    VideoPlayerController controller;
    if (isLocal && isHls) {
      final fileUri = isFileUri ? Uri.parse(url) : Uri.file(url);
      controller = VideoPlayerController.networkUrl(
        fileUri,
        formatHint: VideoFormat.hls,
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );
      _headers = const {};
    } else if (isLocal) {
      final file = isFileUri ? File(Uri.parse(url).toFilePath()) : File(url);
      controller = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );
      _headers = const {};
    } else {
      final uri = Uri.parse(url);
      final mergedHeaders = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'uz,ru;q=0.9,en;q=0.8',
      };
      final defaultReferer = _defaultRefererFor(widget.args.provider);
      if (defaultReferer != null) mergedHeaders['Referer'] = defaultReferer;
      mergedHeaders.addAll(headers);

      debugPrint('[PLAYER] provider: ${widget.args.provider}');
      debugPrint('[PLAYER] headers (${mergedHeaders.length}):');
      mergedHeaders.forEach((k, v) {
        debugPrint('[PLAYER]   $k: $v');
      });

      controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: mergedHeaders,
        formatHint: isHls ? VideoFormat.hls : null,
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );
      _headers = mergedHeaders;
    }
    _controller = controller;
    _videoUrl = url;
    _mediaType = type;

    try {
      await controller.initialize();
      debugPrint(
        '[PLAYER] initialize completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      if (controller.value.hasError) {
        final raw = controller.value.errorDescription;
        debugPrint('[PLAYER] init error: $raw');
        setState(() {
          _initializing = false;
          _errorMessage = raw == null
              ? 'Could not load video'
              : _humanizeError(raw);
        });
        return;
      }
      controller.addListener(_onMajorChange);
      await controller.setLooping(false);
      await controller.setPlaybackSpeed(_playbackSpeed);
      if (resumeAt > Duration.zero) {
        await controller.seekTo(resumeAt);
      }
      await controller.play();
      debugPrint(
        '[PLAYER] play started — total ${stopwatch.elapsedMilliseconds}ms',
      );
      setState(() {
        _initializing = false;
        _errorMessage = null;
      });
      _scheduleHide();
    } on PlatformException catch (e) {
      debugPrint('[PLAYER] platform exception ${e.code}: ${e.message}');
      if (!mounted) return;
      final raw = e.message ?? '';
      String msg;
      if (e.code == 'channel-error') {
        msg = 'Player not ready — please fully restart the app';
      } else if (raw.contains('Cannot Decode') ||
          raw.contains('-12906') ||
          raw.contains('-12939') ||
          raw.contains('CoreMediaError')) {
        msg =
            'This video format is not supported on your device. Try a different quality.';
        if (!_autoFallbackUsed && _videoSources.length > 1) {
          _autoRetrying = true;
          _autoRetry();
          return;
        }
      } else if (_isRecoverableError(raw) && _retryAttempts < 2) {
        debugPrint('[PLAYER] recoverable error, retrying (attempt ${_retryAttempts + 1})');
        _retryAttempts++;
        _autoRetrying = true;
        _autoRetry();
        return;
      } else {
        msg = raw.isEmpty ? 'Could not load video' : _humanizeError(raw);
      }
      setState(() {
        _initializing = false;
        _errorMessage = msg;
      });
    } catch (e) {
      debugPrint('[PLAYER] init threw: $e');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _wasPlaying = false;
  bool _wasBuffering = false;
  bool _wasInitialized = false;
  String? _lastError;

  String _humanizeError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('mediacodec') ||
        lower.contains('decoder') ||
        lower.contains('renderer')) {
      return 'This device couldn\'t decode the video. Try a different quality or retry.';
    }
    if (lower.contains('source error') ||
        lower.contains('unrecognizedinputformat') ||
        lower.contains('nodeclaredbrand')) {
      return 'Couldn\'t open the video source (the server may have blocked it). Try a different quality.';
    }
    if (lower.contains('http data source')) {
      return 'Network error — check your connection';
    }
    if (lower.contains('cannot decode') ||
        lower.contains('-12906') ||
        lower.contains('coremediaerror')) {
      return 'This video format is not supported on your device. Try a different quality.';
    }
    return raw;
  }

  bool _isRecoverableError(String msg) {
    final l = msg.toLowerCase();
    // Never retry format/config/404 errors — these will always fail
    if (l.contains('-12939') ||
        l.contains('-12938') ||
        l.contains('404') ||
        l.contains('not found') ||
        l.contains('coremediaerror') ||
        l.contains('cannot decode') ||
        l.contains('-12906')) {
      return false;
    }
    return l.contains('timed out') ||
        l.contains('timeout') ||
        l.contains('-1001') ||
        l.contains('-1005') ||
        l.contains('source error') ||
        l.contains('mediacodec') ||
        l.contains('decoder') ||
        l.contains('renderer');
  }

  void _onMajorChange() {
    final c = _controller;
    if (c == null) return;
    final v = c.value;

    if (v.hasError) {
      final msg = v.errorDescription;
      if (msg != null && msg != _lastError && mounted) {
        _lastError = msg;
        if (!_autoRetrying && _retryAttempts < 2 && _isRecoverableError(msg)) {
          _retryAttempts++;
          _autoRetrying = true;
          _autoRetry();
          return;
        }
        setState(() => _errorMessage = _humanizeError(msg));
      }
      return;
    }
    if (v.isInitialized) {
      _retryAttempts = 0;
      _autoRetrying = false;
    }

    var changed = false;
    if (v.isInitialized != _wasInitialized) {
      _wasInitialized = v.isInitialized;
      changed = true;
    }
    if (v.isPlaying != _wasPlaying) {
      _wasPlaying = v.isPlaying;
      changed = true;
      if (_isPip) _refreshPipActions();
      if (v.isPlaying) {
        _playbackWatch.start();
        _scheduleHistorySave();
      } else {
        _playbackWatch.stop();
        _saveHistory();
      }
    }
    if (v.isBuffering != _wasBuffering) {
      _wasBuffering = v.isBuffering;
      changed = true;
    }

    if (v.isInitialized && v.duration.inMilliseconds > 0) {
      final remaining = v.duration - v.position;
      final isEnding = remaining <= const Duration(seconds: 2);
      if (isEnding) {
        if (widget.args.isSerial &&
            _episodeIndex + 1 < widget.args.episodes.length) {
          _saveHistoryForNextEpisode();
          _loadEpisode(_episodeIndex + 1);
          return;
        }
        final url = widget.args.contentUrl;
        if (url != null && url.isNotEmpty) {
          _history.remove(url);
        }
      }
    }

    if (changed && mounted) setState(() {});
  }

  Future<void> _autoRetry() async {
    if (!mounted) return;

    if (!_autoFallbackUsed &&
        _videoSources.length > 1 &&
        _currentSourceIndex >= 0 &&
        _currentSourceIndex + 1 < _videoSources.length) {
      final nextIdx = _currentSourceIndex + 1;
      final next = _videoSources[nextIdx];
      _autoFallbackUsed = true;
      setState(() {
        _initializing = true;
        _stage = _LoadingStage.loading;
        _errorMessage = null;
        _currentSourceIndex = nextIdx;
        _currentQuality = next.quality;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switching to ${next.quality}...'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _disposeController();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await _initializeWith(
        url: next.videoUrl,
        headers: _headers.isNotEmpty ? _headers : widget.args.headers,
        type: _mediaType,
      );
      _autoRetrying = false;
      return;
    }

    setState(() {
      _initializing = true;
      _stage = widget.args.isSerial
          ? _LoadingStage.resolving
          : _LoadingStage.loading;
      _errorMessage = null;
    });
    await _disposeController();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (widget.args.isSerial) {
      await _loadEpisode(_episodeIndex, keepRetryCount: true);
    } else if (_videoUrl != null) {
      await _initializeWith(
        url: _videoUrl!,
        headers: _headers,
        type: _mediaType,
      );
    } else {
      await _bootstrap();
    }
    _autoRetrying = false;
  }

  Future<void> _disposeController() async {
    _hideTimer?.cancel();
    final c = _controller;
    if (c != null) {
      c.removeListener(_onMajorChange);
      try {
        await c.pause();
      } catch (_) {}
      await c.dispose();
    }
    _controller = null;
    _wasPlaying = false;
    _wasBuffering = false;
    _wasInitialized = false;
    _lastError = null;
  }

  @override
  void dispose() {
    _saveHistory();
    WidgetsBinding.instance.removeObserver(this);
    _pipChannel.setMethodCallHandler(null);
    _hideTimer?.cancel();
    _historyTimer?.cancel();
    _seekRippleTimer?.cancel();
    _controlsAnimation.dispose();
    _seekRippleController.dispose();
    _scrub.dispose();
    _speedBoost.dispose();
    _swipeIndicator.dispose();
    final c = _controller;
    if (c != null) {
      c.removeListener(_onMajorChange);
      try {
        c.pause();
      } catch (_) {}
      c.dispose();
    }
    _controller = null;
    _restoreSystemUi();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _controlsAnimation.forward();
      _scheduleHide();
    } else {
      _controlsAnimation.reverse();
      _hideTimer?.cancel();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      final c = _controller;
      if (c != null && c.value.isPlaying && _panel == _SidePanel.none) {
        setState(() => _controlsVisible = false);
        _controlsAnimation.reverse();
      }
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
      _scheduleHide();
    }
  }

  void _seekRelative(Duration delta) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = c.value.position + delta;
    final clamped = next < Duration.zero
        ? Duration.zero
        : next > c.value.duration
        ? c.value.duration
        : next;
    c.seekTo(clamped);
    _scheduleHide();
  }

  void _seekTo(Duration position) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    c.seekTo(position);
    _scheduleHide();
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main');
    }
  }

  void _openPanel(_SidePanel panel) {
    setState(() {
      _panel = panel;
      _controlsVisible = true;
    });
    _controlsAnimation.forward();
    _hideTimer?.cancel();
  }

  void _closePanel() {
    setState(() => _panel = _SidePanel.none);
    _scheduleHide();
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    await _controller?.setPlaybackSpeed(speed);
  }

  Future<void> _setSystemBrightness(double value) async {
    try {
      await _systemControlsChannel.invokeMethod<double>('setBrightness', {
        'value': value,
      });
    } catch (_) {}
  }

  Future<void> _setSystemVolume(double value) async {
    try {
      await _systemControlsChannel.invokeMethod<double>('setVolume', {
        'value': value,
      });
    } catch (_) {}
  }

  void _setFit(_PlayerFit fit) {
    setState(() => _fit = fit);
  }

  void _onDoubleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final dx = details.localPosition.dx;
    final width = constraints.maxWidth;
    final leftEdge = width * 0.3;
    final rightEdge = width * 0.7;
    if (dx < leftEdge) {
      _seekRelative(const Duration(seconds: -10));
      _showSeekRipple(-1);
    } else if (dx > rightEdge) {
      _seekRelative(const Duration(seconds: 10));
      _showSeekRipple(1);
    }
  }

  static const double _scrubSecondsPerFullSwipe = 90;

  void _onHDragStart(DragStartDetails _) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      _controlsVisible = true;
      _controlsAnimation.forward();
    }
    _scrub.value = _ScrubState(
      baseline: c.value.position,
      duration: c.value.duration,
      deltaPx: 0,
      span: 1,
    );
  }

  void _onHDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final state = _scrub.value;
    if (state == null) return;
    _scrub.value = state.copyWith(
      deltaPx: state.deltaPx + details.delta.dx,
      span: constraints.maxWidth,
    );
  }

  void _onHDragEnd(DragEndDetails _) {
    final state = _scrub.value;
    final c = _controller;
    _scrub.value = null;
    if (state == null || c == null || !c.value.isInitialized) {
      _scheduleHide();
      return;
    }
    final target = state.previewPosition(_scrubSecondsPerFullSwipe);
    c.seekTo(target);
    _scheduleHide();
  }

  void _onHDragCancel() {
    _scrub.value = null;
    _scheduleHide();
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (_controlsVisible) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized || !c.value.isPlaying) return;
    _speedBeforeBoost = _playbackSpeed;
    _speedBoost.value = true;
    c.setPlaybackSpeed(2.0);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_speedBoost.value) return;
    _speedBoost.value = false;
    final c = _controller;
    final restore = _speedBeforeBoost ?? 1.0;
    _speedBeforeBoost = null;
    if (c != null && c.value.isInitialized) {
      c.setPlaybackSpeed(restore);
    }
  }

  void _showSeekRipple(int direction) {
    if (_seekRippleDirection != direction) {
      _seekRippleSeconds = 10;
    } else {
      _seekRippleSeconds += 10;
    }
    setState(() => _seekRippleDirection = direction);
    _seekRippleController.forward(from: 0);
    _seekRippleTimer?.cancel();
    _seekRippleTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _seekRippleDirection = 0;
        _seekRippleSeconds = 0;
      });
    });
  }

  String _langLabel(String lang) {
    switch (lang.toLowerCase()) {
      case _kSubLang:
        return 'Subtitled (SUB)';
      case _kDubLang:
        return 'Dubbed (DUB)';
      case 'softsub':
        return 'Soft subtitles';
      default:
        return lang.toUpperCase();
    }
  }

  void _openLangSheet() {
    final langs = _availableLangsForCurrentEpisode();
    if (langs.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Audio language',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              for (final l in langs)
                _OptionTile(
                  label: _langLabel(l),
                  selected: l == _currentLang,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _switchLang(l);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadSubtitle(int index) async {
    if (index < 0 || index >= _subtitles.length) {
      setState(() {
        _activeSubtitleIndex = -1;
        _captionFile = null;
      });
      return;
    }
    setState(() => _activeSubtitleIndex = index);
    final sub = _subtitles[index];
    try {
      final response = await Dio().get<String>(
        sub.file,
        options: Options(responseType: ResponseType.plain),
      );
      if (!mounted) return;
      final body = response.data;
      if (body != null && body.isNotEmpty) {
        final isVtt =
            sub.file.toLowerCase().endsWith('.vtt') ||
            body.trimLeft().startsWith('WEBVTT');
        setState(() {
          _captionFile = isVtt
              ? WebVTTCaptionFile(body)
              : SubRipCaptionFile(body);
        });
      }
    } catch (e) {
      debugPrint('[PLAYER] subtitle load error: $e');
    }
  }

  void _disableSubtitle() {
    setState(() {
      _activeSubtitleIndex = -1;
      _captionFile = null;
    });
  }

  void _openSubtitleSheet() {
    if (_subtitles.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.subtitles_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Subtitles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              _OptionTile(
                label: 'Off',
                selected: _activeSubtitleIndex == -1,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _disableSubtitle();
                },
              ),
              for (var i = 0; i < _subtitles.length; i++)
                _OptionTile(
                  label: _subtitles[i].label,
                  selected: i == _activeSubtitleIndex,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _loadSubtitle(i);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    final url = _videoUrl;
    if (url == null || url.isEmpty) return;

    EpisodeEntity? ep;
    if (widget.args.isSerial &&
        _episodeIndex >= 0 &&
        _episodeIndex < widget.args.episodes.length) {
      ep = widget.args.episodes[_episodeIndex];
    }

    final rawId = widget.args.isSerial && ep != null
        ? '${widget.args.contentUrl ?? url}_ep${ep.episode}'
        : widget.args.contentUrl ?? url;
    final id = _stableDownloadId(rawId);

    final existing = _downloads.get(id);
    if (existing != null) {
      if (existing.status == DownloadStatus.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already downloaded'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (existing.status == DownloadStatus.downloading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download in progress'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final item = DownloadItem(
      id: id,
      contentUrl: widget.args.contentUrl ?? '',
      provider: widget.args.provider,
      title: widget.args.title,
      thumbnail: widget.args.thumbnail,
      videoUrl: url,
      localPath: '',
      headers: _headers,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isSerial: widget.args.isSerial,
      episodeNumber: ep?.episode,
      episodeLabel: ep?.label,
    );

    final started = await _downloads.startDownload(item);
    if (!mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is required for downloads'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download started'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _stableDownloadId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(36);
  }

  void _openSettingsSheet() {
    final hasQualities = _videoSources.length > 1;
    final langs = _availableLangsForCurrentEpisode();
    final hasLangs = langs.length > 1;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              _SettingsTile(
                icon: Icons.speed_rounded,
                label: 'Speed',
                value:
                    '${_playbackSpeed.toStringAsFixed(_playbackSpeed == _playbackSpeed.roundToDouble() ? 0 : 2)}x',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openSpeedSheet();
                },
              ),
              _SettingsTile(
                icon: Icons.aspect_ratio_rounded,
                label: 'Aspect',
                value: _fitLabel(_fit),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openFitSheet();
                },
              ),
              if (hasQualities)
                _SettingsTile(
                  icon: Icons.high_quality_rounded,
                  label: 'Quality',
                  value: _currentQuality ?? '—',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openPanel(_SidePanel.quality);
                  },
                ),
              if (hasLangs)
                _SettingsTile(
                  icon: Icons.translate_rounded,
                  label: 'Audio language',
                  value: _currentLang == null ? '—' : _langLabel(_currentLang!),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openLangSheet();
                  },
                ),
              _SettingsTile(
                icon: Icons.subtitles_outlined,
                label: 'Subtitles',
                value: _subtitles.isEmpty
                    ? 'N/A'
                    : _activeSubtitleIndex >= 0
                    ? _subtitles[_activeSubtitleIndex].label
                    : 'Off',
                onTap: _subtitles.isEmpty
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        _openSubtitleSheet();
                      },
              ),
              if (!hasLangs)
                const _SettingsTile(
                  icon: Icons.audiotrack_outlined,
                  label: 'Audio track',
                  value: 'Coming soon',
                  onTap: null,
                ),
              if (widget.args.showDownloadAction)
                _SettingsTile(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  value: '',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _startDownload();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openSpeedSheet() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Playback speed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              for (final s in speeds)
                _OptionTile(
                  label:
                      '${s.toStringAsFixed(s == s.roundToDouble() ? 0 : 2)}x',
                  selected: s == _playbackSpeed,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _setSpeed(s);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openFitSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.aspect_ratio_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Aspect ratio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              for (final fit in _PlayerFit.values)
                _OptionTile(
                  label: _fitLabel(fit),
                  selected: fit == _fit,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _setFit(fit);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _fitLabel(_PlayerFit fit) {
    switch (fit) {
      case _PlayerFit.contain:
        return 'Original';
      case _PlayerFit.cover:
        return 'Fill';
      case _PlayerFit.fill:
        return 'Stretch';
    }
  }

  String _episodeTitle() {
    if (!widget.args.isSerial) return widget.args.title;
    final ep = widget.args.episodes[_episodeIndex];
    final fallback = 'Episode ${ep.episode}';
    final label = ep.label.trim().isEmpty ? fallback : ep.label;
    return '${widget.args.title} · $label';
  }

  Future<void> _retry() async {
    if (widget.args.isSerial) {
      await _loadEpisode(_episodeIndex);
    } else if (_videoUrl != null) {
      setState(() {
        _initializing = true;
        _stage = _LoadingStage.loading;
        _errorMessage = null;
      });
      await _disposeController();
      await _initializeWith(
        url: _videoUrl!,
        headers: _headers,
        type: _mediaType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) => _restoreSystemUi(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _locked ? null : _toggleControls,
              onDoubleTapDown: _locked
                  ? null
                  : (d) => _onDoubleTapDown(d, constraints),
              onDoubleTap: _locked ? null : () {},
              onPanStart: _locked ? null : (d) => _onPanStart(d, constraints),
              onPanUpdate: _locked ? null : (d) => _onPanUpdate(d, constraints),
              onPanEnd: _locked ? null : _onPanEnd,
              onPanCancel: _locked ? null : _onPanCancel,
              onLongPressStart: _locked ? null : _onLongPressStart,
              onLongPressEnd: _locked ? null : _onLongPressEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoLayer(),
                  _buildSubtitleOverlay(),
                  if (!_locked) _buildSeekRipple(),
                  if (_locked) _buildLockOverlay() else _buildControlsOverlay(),
                  if (!_locked) _buildScrubOverlay(),
                  if (!_locked) _buildSpeedBoostBadge(),
                  if (!_locked) _buildSwipeIndicator(),
                  if (!_locked && _panel != _SidePanel.none) _buildSidePanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_initializing) {
      return ColoredBox(
        color: Colors.black,
        child: _LoadingOverlay(stage: _stage, title: _episodeTitle()),
      );
    }
    if (_errorMessage != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return RepaintBoundary(
      child: ColoredBox(
        color: Colors.black,
        child: _FittedVideo(controller: c, fit: _fit),
      ),
    );
  }

  Widget _buildSubtitleOverlay() {
    final c = _controller;
    final captions = _captionFile;
    if (c == null || !c.value.isInitialized || captions == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 16,
      right: 16,
      bottom: _controlsVisible ? 100 : 24,
      child: IgnorePointer(
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: c,
          builder: (_, value, _) {
            final position = value.position;
            Caption? active;
            for (final caption in captions.captions) {
              if (position >= caption.start && position <= caption.end) {
                active = caption;
                break;
              }
            }
            if (active == null || active.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  active.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpeedBoostBadge() {
    return ValueListenableBuilder<bool>(
      valueListenable: _speedBoost,
      builder: (_, active, _) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          top: active ? 24 : -80,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: active ? 1 : 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '2x speed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrubOverlay() {
    return ValueListenableBuilder<_ScrubState?>(
      valueListenable: _scrub,
      builder: (_, state, _) {
        if (state == null) return const SizedBox.shrink();
        final preview = state.previewPosition(_scrubSecondsPerFullSwipe);
        final deltaSeconds = (preview - state.baseline).inSeconds;
        final isForward = deltaSeconds >= 0;
        return IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isForward
                            ? Icons.fast_forward_rounded
                            : Icons.fast_rewind_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isForward ? '+' : '−'}${deltaSeconds.abs()}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDuration(preview)} / ${_formatDuration(state.duration)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeekRipple() {
    if (_seekRippleDirection == 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: _seekRippleDirection < 0
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: AnimatedBuilder(
          animation: _seekRippleController,
          builder: (_, _) {
            final t = _seekRippleController.value;
            return Opacity(
              opacity: 1 - (t * 0.3),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _seekRippleDirection < 0
                          ? Icons.fast_rewind_rounded
                          : Icons.fast_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_seekRippleSeconds}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails d, BoxConstraints constraints) {
    _dragStart = d.localPosition;
    _dragIsHorizontal = null;
    _dragSwipeType = null;
  }

  void _onPanUpdate(DragUpdateDetails d, BoxConstraints constraints) {
    final start = _dragStart;
    if (start == null) return;

    if (_dragIsHorizontal == null) {
      final dx = (d.localPosition.dx - start.dx).abs();
      final dy = (d.localPosition.dy - start.dy).abs();
      if (dx < 8 && dy < 8) return;
      _dragIsHorizontal = dx > dy;

      if (_dragIsHorizontal!) {
        _onHDragStart(
          DragStartDetails(
            globalPosition: d.globalPosition,
            localPosition: d.localPosition,
          ),
        );
      } else {
        final isLeft = start.dx < constraints.maxWidth * 0.5;
        _dragSwipeType = isLeft ? _SwipeType.brightness : _SwipeType.volume;
      }
    }

    if (_dragIsHorizontal!) {
      _onHDragUpdate(d, constraints);
    } else {
      final delta = -(d.delta.dy) / (constraints.maxHeight * 0.7);
      if (_dragSwipeType == _SwipeType.brightness) {
        _brightness = (_brightness + delta).clamp(0.0, 1.0).toDouble();
        unawaited(_setSystemBrightness(_brightness));
        _swipeIndicator.value = _SwipeIndicator(
          _SwipeType.brightness,
          _brightness,
        );
      } else {
        _volume = (_volume + delta).clamp(0.0, 1.0).toDouble();
        unawaited(_setSystemVolume(_volume));
        _swipeIndicator.value = _SwipeIndicator(_SwipeType.volume, _volume);
      }
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_dragIsHorizontal == true) {
      _onHDragEnd(d);
    } else if (_dragSwipeType != null) {
      final type = _dragSwipeType;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_swipeIndicator.value?.type == type) {
          _swipeIndicator.value = null;
        }
      });
    }
    _dragStart = null;
    _dragIsHorizontal = null;
    _dragSwipeType = null;
  }

  void _onPanCancel() {
    if (_dragIsHorizontal == true) _onHDragCancel();
    _swipeIndicator.value = null;
    _dragStart = null;
    _dragIsHorizontal = null;
    _dragSwipeType = null;
  }

  Widget _buildSwipeIndicator() {
    return ValueListenableBuilder<_SwipeIndicator?>(
      valueListenable: _swipeIndicator,
      builder: (_, indicator, _) {
        if (indicator == null) return const SizedBox.shrink();
        final isBrightness = indicator.type == _SwipeType.brightness;
        return Positioned(
          top: 0,
          bottom: 0,
          left: isBrightness ? 48 : null,
          right: isBrightness ? null : 48,
          child: Center(
            child: Container(
              width: 40,
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    isBrightness
                        ? Icons.brightness_6_rounded
                        : indicator.value > 0
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: indicator.value,
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(indicator.value * 100).round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _locked = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tap to unlock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (_isPip) return const SizedBox.shrink();
    final c = _controller;
    final initialized = c != null && c.value.isInitialized;
    final hasEpisodes = widget.args.isSerial && widget.args.episodes.isNotEmpty;
    final hasQualities = _videoSources.length > 1;
    final hasLangSwitcher = _availableLangsForCurrentEpisode().length > 1;
    final isBuffering = c != null && c.value.isBuffering;

    return FadeTransition(
      opacity: _controlsAnimation,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: Stack(
          children: [
            const Positioned.fill(child: _ControlsScrim()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _IconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: _exit,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _episodeTitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasLangSwitcher) ...[
                        _LangPill(
                          label: (_currentLang ?? _kSubLang).toUpperCase(),
                          onTap: _openLangSheet,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _IconButton(
                        icon: _isPortrait
                            ? Icons.screen_lock_landscape_rounded
                            : Icons.screen_lock_portrait_rounded,
                        onTap: _toggleOrientation,
                      ),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: Icons.lock_outline_rounded,
                        onTap: () => setState(() {
                          _locked = true;
                          _controlsVisible = false;
                          _controlsAnimation.reverse();
                          _hideTimer?.cancel();
                        }),
                      ),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: Icons.picture_in_picture_alt_rounded,
                        onTap: _enterPip,
                      ),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: Icons.settings_outlined,
                        onTap: _openSettingsSheet,
                      ),
                      const SizedBox(width: 8),
                      _IconButton(
                        icon: hasEpisodes
                            ? Icons.video_library_rounded
                            : Icons.high_quality_rounded,
                        onTap: hasEpisodes
                            ? () => _openPanel(_SidePanel.episodes)
                            : hasQualities
                            ? () => _openPanel(_SidePanel.quality)
                            : _openSettingsSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (initialized && !isBuffering) _buildCenterPlayCluster(c),
            if (isBuffering)
              const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.8,
                  ),
                ),
              ),
            if (initialized) _buildBottomBar(c, hasEpisodes, hasQualities),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayCluster(VideoPlayerController c) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CenterIconButton(
            icon: Icons.replay_10_rounded,
            onTap: () {
              _seekRelative(const Duration(seconds: -10));
              _showSeekRipple(-1);
            },
          ),
          const SizedBox(width: 28),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: c,
            builder: (_, value, _) => _CenterIconButton(
              icon: value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onTap: _togglePlay,
              large: true,
            ),
          ),
          const SizedBox(width: 28),
          _CenterIconButton(
            icon: Icons.forward_10_rounded,
            onTap: () {
              _seekRelative(const Duration(seconds: 10));
              _showSeekRipple(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    VideoPlayerController c,
    bool hasEpisodes,
    bool hasQualities,
  ) {
    final hasNext =
        hasEpisodes && _episodeIndex + 1 < widget.args.episodes.length;
    final hasPrev = hasEpisodes && _episodeIndex - 1 >= 0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: c,
                builder: (_, value, _) {
                  final position = value.position;
                  final duration = value.duration.inMilliseconds == 0
                      ? Duration.zero
                      : value.duration;
                  return Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Slider(
                            value: duration.inMilliseconds == 0
                                ? 0
                                : position.inMilliseconds
                                      .clamp(0, duration.inMilliseconds)
                                      .toDouble(),
                            min: 0,
                            max: duration.inMilliseconds.toDouble().clamp(
                              1,
                              double.infinity,
                            ),
                            onChanged: (v) {
                              _seekTo(Duration(milliseconds: v.toInt()));
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (hasEpisodes)
                      _BottomTextButton(
                        icon: Icons.skip_previous_rounded,
                        label: 'Previous',
                        enabled: hasPrev,
                        onTap: () => _loadEpisode(_episodeIndex - 1),
                      ),
                    if (hasEpisodes)
                      _BottomTextButton(
                        icon: Icons.skip_next_rounded,
                        label: 'Next',
                        enabled: hasNext,
                        onTap: () => _loadEpisode(_episodeIndex + 1),
                      ),
                    _BottomTextButton(
                      icon: Icons.speed_rounded,
                      label:
                          '${_playbackSpeed.toStringAsFixed(_playbackSpeed == _playbackSpeed.roundToDouble() ? 0 : 2)}x',
                      enabled: true,
                      onTap: _openSpeedSheet,
                    ),
                    if (hasQualities)
                      _BottomTextButton(
                        icon: Icons.high_quality_rounded,
                        label: _currentQuality ?? 'Quality',
                        enabled: true,
                        onTap: () => _openPanel(_SidePanel.quality),
                      ),
                    if (hasEpisodes)
                      _BottomTextButton(
                        icon: Icons.list_rounded,
                        label: 'Episodes',
                        enabled: true,
                        onTap: () => _openPanel(_SidePanel.episodes),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    final isQuality = _panel == _SidePanel.quality;
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: 320,
      child: Material(
        color: Colors.black.withValues(alpha: 0.92),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Text(
                      isQuality ? 'Quality' : 'Episodes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _closePanel,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isQuality
                    ? ListView.separated(
                        itemCount: _videoSources.length,
                        separatorBuilder: (_, _) => Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 1,
                        ),
                        itemBuilder: (_, i) {
                          final src = _videoSources[i];
                          return _QualityRow(
                            source: src,
                            isActive: src.quality == _currentQuality,
                            onTap: () => _switchQuality(src),
                          );
                        },
                      )
                    : ListView.separated(
                        itemCount: widget.args.episodes.length,
                        separatorBuilder: (_, _) => Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 1,
                        ),
                        itemBuilder: (_, i) => _EpisodeRow(
                          episode: widget.args.episodes[i],
                          isActive: i == _episodeIndex,
                          onTap: () => _loadEpisode(i),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FittedVideo extends StatelessWidget {
  const _FittedVideo({required this.controller, required this.fit});
  final VideoPlayerController controller;
  final _PlayerFit fit;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final hasSize = size.width > 0 && size.height > 0;
    final natW = hasSize ? size.width : 1920.0;
    final natH = hasSize ? size.height : 1080.0;
    final aspect = natW / natH;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final boxH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final boxAspect = boxH == 0 ? aspect : boxW / boxH;

        double targetW;
        double targetH;
        switch (fit) {
          case _PlayerFit.contain:
            if (aspect > boxAspect) {
              targetW = boxW;
              targetH = boxW / aspect;
            } else {
              targetH = boxH;
              targetW = boxH * aspect;
            }
          case _PlayerFit.cover:
            if (aspect > boxAspect) {
              targetH = boxH;
              targetW = boxH * aspect;
            } else {
              targetW = boxW;
              targetH = boxW / aspect;
            }
          case _PlayerFit.fill:
            targetW = boxW;
            targetH = boxH;
        }

        return ClipRect(
          child: SizedBox(
            width: boxW,
            height: boxH,
            child: Center(
              child: SizedBox(
                width: targetW,
                height: targetH,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}

class _ControlsScrim extends StatelessWidget {
  const _ControlsScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Color(0x33000000),
            Color(0x00000000),
            Color(0x33000000),
            Color(0xCC000000),
          ],
          stops: [0.0, 0.18, 0.5, 0.82, 1.0],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.stage, required this.title});

  final _LoadingStage stage;
  final String title;

  String get _label {
    switch (stage) {
      case _LoadingStage.resolving:
        return 'Extracting media…';
      case _LoadingStage.loading:
        return 'Loading video…';
    }
  }

  String get _hint {
    switch (stage) {
      case _LoadingStage.resolving:
        return 'Fetching playback link from provider';
      case _LoadingStage.loading:
        return 'Preparing video stream';
    }
  }

  IconData get _icon {
    switch (stage) {
      case _LoadingStage.resolving:
        return Icons.cloud_download_outlined;
      case _LoadingStage.loading:
        return Icons.movie_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_icon, color: Colors.white70, size: 36),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey(stage),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterIconButton extends StatelessWidget {
  const _CenterIconButton({
    required this.icon,
    required this.onTap,
    this.large = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 52.0;
    final iconSize = large ? 42.0 : 28.0;
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _BottomTextButton extends StatelessWidget {
  const _BottomTextButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white38;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.episode,
    required this.isActive,
    required this.onTap,
  });

  final EpisodeEntity episode;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = episode.label.trim().isEmpty
        ? 'Episode ${episode.episode}'
        : episode.label;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                episode.episode.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: isActive ? AppColors.primary : Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({
    required this.source,
    required this.isActive,
    required this.onTap,
  });

  final VideoSourceEntity source;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isActive
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isActive ? AppColors.primary : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                source.quality,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (source.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: disabled ? Colors.white38 : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled ? Colors.white54 : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: disabled ? Colors.white38 : Colors.white70,
                fontSize: 13,
              ),
            ),
            if (!disabled) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrubState {
  final Duration baseline;
  final Duration duration;
  final double deltaPx;
  final double span;

  const _ScrubState({
    required this.baseline,
    required this.duration,
    required this.deltaPx,
    required this.span,
  });

  _ScrubState copyWith({double? deltaPx, double? span}) => _ScrubState(
    baseline: baseline,
    duration: duration,
    deltaPx: deltaPx ?? this.deltaPx,
    span: span ?? this.span,
  );

  Duration previewPosition(double secondsPerFullSwipe) {
    if (span <= 0 || duration.inMilliseconds <= 0) return baseline;
    final fraction = (deltaPx / span).clamp(-1.0, 1.0);
    final deltaMs = (fraction * secondsPerFullSwipe * 1000).round();
    final target = baseline.inMilliseconds + deltaMs;
    final clamped = target.clamp(0, duration.inMilliseconds);
    return Duration(milliseconds: clamped);
  }
}
