import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_bloc.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_event.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_state.dart';
import 'package:soplay/features/shorts/presentation/widgets/short_reel_item.dart' hide ShortEntity;
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
    if (oldWidget.refreshTick != widget.refreshTick) {
      _refresh();
    }
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
      _controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
                  context.read<ShortsBloc>().add(const ShortsLoad()),
            ),
            ShortsLoaded(:final items) => items.isEmpty
                ? const ShortsEmptyView()
                : Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    context
                        .read<ShortsBloc>()
                        .add(ShortsPageChanged(index));
                  },
                  itemBuilder: (context, index) {
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
                if (state.refreshing)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top,
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