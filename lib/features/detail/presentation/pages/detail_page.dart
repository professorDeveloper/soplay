import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/detail/domain/entities/detail_entity.dart';
import 'package:soplay/features/detail/domain/entities/episodes_args.dart';
import 'package:soplay/features/detail/domain/entities/playback_entity.dart';
import 'package:soplay/features/detail/domain/entities/player_args.dart';
import 'package:soplay/features/detail/presentation/blocs/detail_bloc/detail_bloc.dart';
import 'package:soplay/features/detail/presentation/blocs/episodes_bloc/episodes_bloc.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_cast_tab.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_comments_tab.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_hero.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_info.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_related.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_screenshots.dart';
import 'package:soplay/features/detail/presentation/widgets/detail_skeleton.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.args});
  final DetailArgs args;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<DetailBloc>()..add(DetailLoad(args.contentUrl)),
        ),
        BlocProvider(create: (_) => getIt<EpisodesBloc>()),
      ],
      child: _DetailScaffold(contentUrl: args.contentUrl),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.contentUrl});
  final String contentUrl;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<DetailBloc, DetailState>(
          builder: (context, state) {
            return switch (state) {
              DetailInitial() || DetailLoading() => Stack(
                  children: [
                    const DetailSkeleton(),
                    _BackOnlyBar(onBack: () => _goBack(context)),
                  ],
                ),
              DetailLoaded(:final detail) => _DetailView(detail: detail),
              DetailError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () =>
                      context.read<DetailBloc>().add(DetailLoad(contentUrl)),
                  onBack: () => _goBack(context),
                ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main');
    }
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.detail});
  final DetailEntity detail;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bodyPlayKey = GlobalKey();

  final ValueNotifier<double> _collapse = ValueNotifier<double>(0);
  final ValueNotifier<bool> _showPill = ValueNotifier<bool>(false);

  late final List<String> _tabs;
  late final bool _hasCast;
  late final bool _hasShots;
  double _collapseRange = 1;
  bool _isInList = false;

  @override
  void initState() {
    super.initState();
    _hasCast = widget.detail.cast.isNotEmpty ||
        (widget.detail.director?.trim().isNotEmpty ?? false);
    _hasShots = widget.detail.screenshots.isNotEmpty;
    _tabs = [
      'Similar',
      if (_hasCast) 'Cast',
      'Comments',
      if (_hasShots) 'Screenshots',
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (mounted) setState(() {});
  }

  double _swipeAccum = 0;

  void _onSwipeStart(DragStartDetails _) {
    _swipeAccum = 0;
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    _swipeAccum += details.primaryDelta ?? 0;
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _swipeAccum;
    final i = _tabController.index;
    final goNext = (velocity < -80) || (distance < -40);
    final goPrev = (velocity > 80) || (distance > 40);
    if (goNext && i < _tabs.length - 1) {
      _tabController.animateTo(i + 1);
    } else if (goPrev && i > 0) {
      _tabController.animateTo(i - 1);
    }
    _swipeAccum = 0;
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final v = (offset / _collapseRange).clamp(0.0, 1.0);
    if ((v - _collapse.value).abs() > 0.005) {
      _collapse.value = v;
    }

    final renderBox =
        _bodyPlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final pos = renderBox.localToGlobal(Offset.zero);
      final topThreshold =
          MediaQuery.paddingOf(context).top + kToolbarHeight - 4;
      final hidden = (pos.dy + renderBox.size.height) < topThreshold;
      if (hidden != _showPill.value) {
        _showPill.value = hidden;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _collapse.dispose();
    _showPill.dispose();
    super.dispose();
  }

  Widget _buildTabContent(DetailEntity detail) {
    final tab = _tabs[_tabController.index];
    return KeyedSubtree(
      key: ValueKey('detail-tab-$tab'),
      child: switch (tab) {
        'Similar' => DetailRelatedSection(related: detail.related),
        'Cast' => DetailCastTab(
            cast: detail.cast,
            director: detail.director,
          ),
        'Comments' => DetailCommentsTab(
            provider: detail.provider,
            contentUrl: detail.contentUrl,
          ),
        'Screenshots' => DetailScreenshotsSection(
            screenshots: detail.screenshots,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onPrimaryAction() {
    final state = context.read<EpisodesBloc>().state;
    if (state is EpisodesLoading) return;
    context.read<EpisodesBloc>().add(EpisodesLoad(widget.detail.contentUrl));
  }

  void _toggleMyList() {
    setState(() => _isInList = !_isInList);
    _showSnack(_isInList ? 'Added to My List' : 'Removed from My List');
  }

  void _onShare() => _showSnack('Share link copied');

  void _handlePlayback(PlaybackEntity playback) {
    if (playback.isSerial) {
      if (playback.episodes.isEmpty) {
        _showSnack('No episodes available');
        return;
      }
      context.push(
        '/episodes',
        extra: EpisodesArgs(
          title: widget.detail.title,
          contentUrl: playback.contentUrl.isNotEmpty
              ? playback.contentUrl
              : widget.detail.contentUrl,
          provider: playback.provider,
          episodes: playback.episodes,
          headers: playback.headers,
          page: playback.page,
          size: playback.size,
          total: playback.total,
          totalPages: playback.totalPages,
        ),
      );
      return;
    }

    var movieUrl = playback.playerSrc;
    if (movieUrl == null || movieUrl.isEmpty) {
      final sources = playback.videoSources;
      String? pickedUrl;
      for (final s in sources) {
        if (s.isDefault && s.accessible) {
          pickedUrl = s.videoUrl;
          break;
        }
      }
      if (pickedUrl == null) {
        for (final s in sources) {
          if (s.accessible) {
            pickedUrl = s.videoUrl;
            break;
          }
        }
      }
      pickedUrl ??= sources.isNotEmpty ? sources.first.videoUrl : null;
      movieUrl = pickedUrl;
    }
    if (movieUrl == null || movieUrl.isEmpty) {
      _showSnack('No playable source');
      return;
    }
    context.push(
      '/player',
      extra: PlayerArgs(
        title: widget.detail.title,
        provider: playback.provider,
        headers: playback.headers,
        movieUrl: movieUrl,
        videoSources: playback.videoSources,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final screenH = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenH * 0.55).clamp(320.0, 440.0);
    const toolbarHeight = kToolbarHeight;
    _collapseRange = heroHeight - toolbarHeight;

    final detail = widget.detail;

    return BlocListener<EpisodesBloc, EpisodesState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is EpisodesLoaded) {
          _handlePlayback(state.playback);
          context.read<EpisodesBloc>().add(const EpisodesReset());
        } else if (state is EpisodesError) {
          _showSnack(state.message);
          context.read<EpisodesBloc>().add(const EpisodesReset());
        }
      },
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: heroHeight + topPad,
                collapsedHeight: toolbarHeight,
                pinned: true,
                backgroundColor: AppColors.background,
                automaticallyImplyLeading: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: toolbarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: ValueListenableBuilder<double>(
                    valueListenable: _collapse,
                    builder: (_, c, _) => Opacity(
                      opacity: (1 - c).clamp(0.0, 1.0),
                      child: DetailHeroBackground(
                        thumbnail: detail.thumbnail,
                        title: detail.title,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: DetailContentHeader(
                  detail: detail,
                  onPrimaryAction: _onPrimaryAction,
                  playButtonKey: _bodyPlayKey,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textHint,
                    dividerColor: Colors.transparent,
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: MediaQuery.paddingOf(context).bottom + 32,
                ),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: _onSwipeStart,
                    onHorizontalDragUpdate: _onSwipeUpdate,
                    onHorizontalDragEnd: _onSwipeEnd,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (MediaQuery.sizeOf(context).height -
                                topPad -
                                toolbarHeight -
                                kTextTabBarHeight -
                                MediaQuery.paddingOf(context).bottom -
                                36)
                            .clamp(0.0, double.infinity),
                      ),
                      child: _buildTabContent(detail),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _collapse,
              builder: (_, c, _) => ValueListenableBuilder<bool>(
                valueListenable: _showPill,
                builder: (_, showPill, _) =>
                    BlocBuilder<EpisodesBloc, EpisodesState>(
                  buildWhen: (a, b) =>
                      (a is EpisodesLoading) != (b is EpisodesLoading),
                  builder: (context, state) => _AnimatedTopBar(
                    collapse: c,
                    showPill: showPill,
                    title: detail.title,
                    isInList: _isInList,
                    isLoading: state is EpisodesLoading,
                    onBack: _goBack,
                    onPrimaryAction: _onPrimaryAction,
                    onAddToList: _toggleMyList,
                    onShare: _onShare,
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<EpisodesBloc, EpisodesState>(
            buildWhen: (a, b) =>
                (a is EpisodesLoading) != (b is EpisodesLoading),
            builder: (_, state) {
              if (state is! EpisodesLoading) return const SizedBox.shrink();
              return const _PlaybackLoadingOverlay();
            },
          ),
        ],
      ),
    );
  }
}

class _PlaybackLoadingOverlay extends StatelessWidget {
  const _PlaybackLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: const Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTopBar extends StatelessWidget {
  const _AnimatedTopBar({
    required this.collapse,
    required this.showPill,
    required this.title,
    required this.isInList,
    required this.isLoading,
    required this.onBack,
    required this.onPrimaryAction,
    required this.onAddToList,
    required this.onShare,
  });

  final double collapse;
  final bool showPill;
  final String title;
  final bool isInList;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onPrimaryAction;
  final VoidCallback onAddToList;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final solidOpacity = Curves.easeIn.transform(collapse).clamp(0.0, 1.0);
    final titleOpacity = ((collapse - 0.6) / 0.3).clamp(0.0, 1.0);

    return Stack(
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: solidOpacity,
            child: Container(
              height: topPad + kToolbarHeight,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.96),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider.withValues(alpha: solidOpacity),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: topPad + 6, left: 8, right: 8),
          child: SizedBox(
            height: kToolbarHeight - 12,
            child: Row(
              children: [
                _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: titleOpacity,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.25, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: showPill
                      ? Padding(
                          key: const ValueKey('pill'),
                          padding: const EdgeInsets.only(right: 8),
                          child: _ActionPill(
                            onTap: onPrimaryAction,
                            isLoading: isLoading,
                          ),
                        )
                      : const SizedBox(key: ValueKey('no-pill'), width: 0),
                ),
                _CircleIconButton(
                  icon: isInList ? Icons.check_rounded : Icons.add_rounded,
                  onTap: onAddToList,
                ),
                const SizedBox(width: 8),
                _CircleIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
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
            width: 36,
            height: 36,
            color: Colors.black.withValues(alpha: 0.42),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.onTap, required this.isLoading});
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              else
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: Colors.black,
                ),
              const SizedBox(width: 4),
              const Text(
                'Play',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          SizedBox(
            height: tabBar.preferredSize.height,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: tabBar,
            ),
          ),
          Container(height: 0.5, color: AppColors.divider),
        ],
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 0.5;

  @override
  double get minExtent => tabBar.preferredSize.height + 0.5;

  @override
  bool shouldRebuild(_TabBarDelegate old) => tabBar != old.tabBar;
}

class _BackOnlyBar extends StatelessWidget {
  const _BackOnlyBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPad + 8,
      left: 8,
      child: GestureDetector(
        onTap: onBack,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: topPad + 8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceVariant,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textHint,
            size: 52,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          const Spacer(),
        ],
      ),
    );
  }
}
