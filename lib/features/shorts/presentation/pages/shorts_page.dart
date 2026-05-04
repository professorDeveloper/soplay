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
                                  width: 32,
                                  height: 32,
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
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: topPad + 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: EdgeInsets.only(
                                top: topPad + 12, left: 16),
                            alignment: Alignment.topLeft,
                            child: const Text(
                              'Shorts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                      color: Colors.black87, blurRadius: 8),
                                ],
                              ),
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
