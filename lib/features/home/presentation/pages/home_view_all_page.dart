import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_event.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_state.dart';
import 'package:soplay/features/home/presentation/widgets/view_all_widgets.dart';

class HomeViewAllPage extends StatefulWidget {
  const HomeViewAllPage({
    super.key,
    required this.keyCat,
    required this.title,
    this.slug = '',
  });

  final String keyCat;
  final String? slug;
  final String title;

  @override
  State<HomeViewAllPage> createState() => _HomeViewAllPageState();
}

class _HomeViewAllPageState extends State<HomeViewAllPage> {
  late final ScrollController _scroll;
  final _blurProgress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    context.read<ViewAllBloc>().add(
      ViewAllLoad(key: widget.keyCat, slug: widget.slug),
    );
  }

  void _onScroll() {
    final next = (_scroll.offset / 80).clamp(0.0, 1.0);
    if ((next - _blurProgress.value).abs() >= 0.02) _blurProgress.value = next;

    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<ViewAllBloc>().add(ViewAllLoadMore());
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _blurProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final appBarH = topPad + 56.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          BlocBuilder<ViewAllBloc, ViewAllState>(
            builder: (context, state) {
              if (state is ViewAllLoading) {
                return ViewAllSkeleton(appBarH: appBarH);
              }
              if (state is ViewAllError) {
                return ViewAllErrorView(
                  message: state.mesage,
                  onRetry: () => context.read<ViewAllBloc>().add(
                    ViewAllLoad(key: widget.keyCat, slug: widget.slug),
                  ),
                );
              }
              if (state is ViewAllLoaded) {
                return ViewAllGrid(
                  state: state,
                  scroll: _scroll,
                  appBarH: appBarH,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _blurProgress,
              builder: (_, progress, _) => ViewAllAppBar(
                title: widget.title,
                blurProgress: progress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
