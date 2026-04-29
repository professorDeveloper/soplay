import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/domain/entities/view_all.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_event.dart';
import 'package:soplay/features/home/presentation/widgets/home_banner.dart';
import 'package:soplay/features/home/presentation/widgets/home_movie_section.dart';
import 'package:soplay/features/home/presentation/widgets/home_top_bar.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';

import '../bloc/home/home_state.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, required this.state});

  final HomeLoaded state;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final ScrollController _scrollController;

  final _blurProgress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    final next = _scrollController.hasClients
        ? (_scrollController.offset / 96).clamp(0.0, 1.0)
        : 0.0;
    if ((next - _blurProgress.value).abs() < 0.02) return;
    _blurProgress.value = next;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _blurProgress.dispose();
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
              if (widget.state.genres.isNotEmpty)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: _GenreSection(genres: widget.state.genres),
                  ),
                ),
              if (widget.state.collectionLoading)
                const SliverToBoxAdapter(child: CollectionLoadingRow()),
              for (final section in widget.state.homeData.sections)
                if (section.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: MovieSection(
                        title: section.label,
                        movies: section.items,
                        type: section.viewAll.type,
                        slug: section.viewAll.slug,
                      ),
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
          child: ValueListenableBuilder<double>(
            valueListenable: _blurProgress,
            builder: (_, progress, _) => HomeTopBar(blurProgress: progress),
          ),
        ),
      ],
    );
  }
}

class _GenreSection extends StatelessWidget {
  const _GenreSection({required this.genres});

  final List<GenreEntity> genres;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(17, 18, 16, 12),
            child: Text(
              'Janrlar',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: genres.length,
              itemBuilder: (_, i) => _GenreCard(genre: genres[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.genre});

  final GenreEntity genre;

  String get _label {
    return genre.slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/view-all',
        extra: ViewAllEntity(type: 'genre', slug: genre.slug),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 110,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                genre.image.isNotEmpty
                    ? Image.network(
                        genre.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: AppColors.surfaceVariant,
                        ),
                      )
                    : const ColoredBox(color: AppColors.surfaceVariant),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Text(
                    _label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
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
}
