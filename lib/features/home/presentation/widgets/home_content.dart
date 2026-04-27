import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/presentation/bloc/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home_event.dart';
import 'package:soplay/features/home/presentation/bloc/home_state.dart';
import 'package:soplay/features/home/presentation/widgets/home_banner.dart';
import 'package:soplay/features/home/presentation/widgets/home_movie_section.dart';
import 'package:soplay/features/home/presentation/widgets/home_top_bar.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, required this.state});

  final HomeLoaded state;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final ScrollController _scrollController;
  double _topBarBlur = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    final nextBlur = _scrollController.hasClients
        ? (_scrollController.offset / 96).clamp(0.0, 1.0)
        : 0.0;
    if ((nextBlur - _topBarBlur).abs() < 0.02) return;
    setState(() => _topBarBlur = nextBlur);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          edgeOffset: topPad + 10,
          displacement: topPad + 10,
          strokeWidth: 2.6,
          onRefresh: () async {
            context.read<HomeBloc>().add(HomeLoad(silent: true));
            await Future.wait([
              context.read<HomeBloc>().stream.firstWhere(
                (state) => state is HomeLoaded || state is HomeError,
              ),
              Future<void>.delayed(const Duration(milliseconds: 850)),
            ]);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeBanner(
                  banners: widget.state.homeData.banner,
                  topPadding: topPad,
                ),
              ),
              if (widget.state.collectionLoading)
                const SliverToBoxAdapter(child: CollectionLoadingRow()),
              if (!widget.state.collectionLoading &&
                  widget.state.collectionItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: MovieSection(
                    title: widget.state.collectionTitle ?? '',
                    movies: widget.state.collectionItems,
                    isHighlighted: true,
                  ),
                ),
              for (final section in widget.state.homeData.sections)
                if (section.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: MovieSection(
                      title: section.label,
                      movies: section.items,
                    ),
                  ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 16,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeTopBar(blurProgress: _topBarBlur),
        ),
      ],
    );
  }
}
