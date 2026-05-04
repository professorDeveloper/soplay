import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_bloc.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_event.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_state.dart';
import 'package:soplay/features/shorts/presentation/widgets/short_reel_item.dart';
import 'package:soplay/features/shorts/presentation/widgets/shorts_state_views.dart';

class ShortsPage extends StatelessWidget {
  const ShortsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShortsBloc>()..add(const ShortsLoad()),
      child: const _ShortsView(),
    );
  }
}

class _ShortsView extends StatefulWidget {
  const _ShortsView();

  @override
  State<_ShortsView> createState() => _ShortsViewState();
}

class _ShortsViewState extends State<_ShortsView>
    with AutomaticKeepAliveClientMixin {
  final PageController _controller = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              onRetry: () => context.read<ShortsBloc>().add(const ShortsLoad()),
            ),
            ShortsLoaded(:final items) =>
              items.isEmpty
                  ? const ShortsEmptyView()
                  : PageView.builder(
                      controller: _controller,
                      scrollDirection: Axis.vertical,
                      itemCount: items.length,
                      onPageChanged: (index) {
                        context.read<ShortsBloc>().add(
                          ShortsPageChanged(index),
                        );
                      },
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ShortReelItem(
                          short: item,
                          active: state.activeIndex == index,
                          likeLoading: state.loadingLikeIds.contains(item.id),
                          onLike: () => context.read<ShortsBloc>().add(
                            ShortsLikeToggled(item.id),
                          ),
                        );
                      },
                    ),
          };
        },
      ),
    );
  }
}
