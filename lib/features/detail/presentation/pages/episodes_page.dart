import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/episode_entity.dart';
import 'package:soplay/features/detail/domain/entities/episodes_args.dart';
import 'package:soplay/features/detail/domain/entities/player_args.dart';
import 'package:soplay/features/detail/domain/usecases/get_episodes_usecase.dart';

class EpisodesPage extends StatefulWidget {
  const EpisodesPage({super.key, required this.args});
  final EpisodesArgs args;

  @override
  State<EpisodesPage> createState() => _EpisodesPageState();
}

class _EpisodesPageState extends State<EpisodesPage> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _blurProgress = ValueNotifier<double>(0);
  late final GetEpisodesUseCase _getEpisodes;

  late List<EpisodeEntity> _episodes;
  late int _page;
  late int _totalPages;
  late int _total;
  late int _size;
  String _sort = 'asc';
  bool _loadingMore = false;
  bool _resorting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getEpisodes = getIt<GetEpisodesUseCase>();
    _episodes = List.of(widget.args.episodes);
    _page = widget.args.page;
    _totalPages = widget.args.totalPages;
    _total = widget.args.total > 0 ? widget.args.total : _episodes.length;
    _size = widget.args.size;
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _blurProgress.dispose();
    super.dispose();
  }

  void _onScroll() {
    final next = (_scroll.offset / 80).clamp(0.0, 1.0);
    if ((next - _blurProgress.value).abs() >= 0.015) {
      _blurProgress.value = next;
    }

    if (!_loadingMore &&
        _page < _totalPages &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    if (widget.args.contentUrl.isEmpty) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });

    final result = await _getEpisodes(
      widget.args.contentUrl,
      page: _page + 1,
      size: _size,
      sort: _sort,
    );

    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _page = value.page;
          _totalPages = value.totalPages;
          _total = value.total > 0 ? value.total : _total;
          _episodes = [..._episodes, ...value.episodes];
          _loadingMore = false;
        });
      case Failure(:final error):
        setState(() {
          _loadingMore = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  Future<void> _toggleSort() async {
    if (_resorting || widget.args.contentUrl.isEmpty) return;
    final next = _sort == 'asc' ? 'desc' : 'asc';
    setState(() {
      _resorting = true;
      _error = null;
    });
    final result = await _getEpisodes(
      widget.args.contentUrl,
      page: 1,
      size: _size,
      sort: next,
    );
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _sort = next;
          _episodes = List.of(value.episodes);
          _page = value.page;
          _totalPages = value.totalPages;
          _total = value.total > 0 ? value.total : _total;
          _resorting = false;
        });
        if (_scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      case Failure(:final error):
        setState(() {
          _resorting = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main');
    }
  }

  void _playFrom(int index) {
    context.push(
      '/player',
      extra: PlayerArgs(
        title: widget.args.title,
        provider: widget.args.provider,
        headers: widget.args.headers,
        episodes: _episodes,
        initialEpisodeIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final appBarH = topPad + 56;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _episodes.isEmpty
                ? const _EmptyState()
                : CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, appBarH + 8, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(
                                child: _CountHeader(
                                  loaded: _episodes.length,
                                  total: _total,
                                ),
                              ),
                              _SortToggle(
                                sort: _sort,
                                busy: _resorting,
                                onTap: _toggleSort,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList.separated(
                        itemCount: _episodes.length,
                        separatorBuilder: (_, _) => const Divider(
                          color: AppColors.divider,
                          height: 1,
                          indent: 76,
                        ),
                        itemBuilder: (_, i) => _EpisodeRow(
                          episode: _episodes[i],
                          onTap: () => _playFrom(i),
                        ),
                      ),
                      if (_loadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_error != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: _LoadMoreError(
                              message: _error!,
                              onRetry: _loadMore,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: bottomPad + 24)),
                    ],
                  ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _blurProgress,
                builder: (_, progress, _) => _EpisodesAppBar(
                  title: widget.args.title,
                  blurProgress: progress,
                  onBack: _goBack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodesAppBar extends StatelessWidget {
  const _EpisodesAppBar({
    required this.title,
    required this.blurProgress,
    required this.onBack,
  });

  final String title;
  final double blurProgress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final progress = blurProgress.clamp(0.0, 1.0);

    final content = Container(
      height: topPad + 56,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9 * progress),
        border: progress > 0.05
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07 * progress),
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: EdgeInsets.fromLTRB(4, topPad + 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (progress < 0.01) return content;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20 * progress, sigmaY: 20 * progress),
        child: content,
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({
    required this.sort,
    required this.busy,
    required this.onTap,
  });
  final String sort;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDesc = sort == 'desc';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Icon(
                  isDesc
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              const SizedBox(width: 6),
              Text(
                isDesc ? 'Newest' : 'Oldest',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.loaded, required this.total});
  final int loaded;
  final int total;

  @override
  Widget build(BuildContext context) {
    final showOf = total > 0 && total > loaded;
    final label = showOf ? '$loaded of $total episodes' : '$total episodes';
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textHint,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.onTap});

  final EpisodeEntity episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSub = episode.hasSub == true;
    final hasDub = episode.hasDub == true;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '${episode.episode}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                episode.label.isNotEmpty
                    ? episode.label
                    : 'Episode ${episode.episode}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasSub) const _LangChip(label: 'SUB', primary: true),
            if (hasSub && hasDub) const SizedBox(width: 4),
            if (hasDub) const _LangChip(label: 'DUB', primary: false),
            if (hasSub || hasDub) const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.primary});
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: AppColors.textHint,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No episodes available',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
