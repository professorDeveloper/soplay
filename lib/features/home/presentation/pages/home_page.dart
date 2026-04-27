import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/presentation/bloc/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home_event.dart';
import 'package:soplay/features/home/presentation/bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoad());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is HomeError) {
          return const _ErrorView();
        }
        if (state is HomeLoaded) {
          return _HomeContent(state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Banner(banners: state.homeData.banner),
        ),
        ...state.homeData.sections.map(
          (section) => SliverToBoxAdapter(
            child: _Section(
              label: section.label,
              items: section.items,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _Banner extends StatefulWidget {
  const _Banner({required this.banners});
  final List<MovieEntity> banners;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final movie = widget.banners[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (movie.thumbnail != null)
                    Image.network(
                      movie.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) =>
                          const _ThumbnailPlaceholder(height: 480),
                      loadingBuilder: (context, child, chunk) =>
                          chunk == null ? child : const _ThumbnailPlaceholder(height: 480),
                    )
                  else
                    const _ThumbnailPlaceholder(height: 480),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: _BannerInfo(movie: movie),
                  ),
                ],
              );
            },
          ),
          if (widget.banners.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.primary : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerInfo extends StatelessWidget {
  const _BannerInfo({required this.movie});
  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'home.watch_now'.tr(),
                isPrimary: true,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                icon: Icons.info_outline_rounded,
                label: 'home.more_info'.tr(),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
  });
  final IconData icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.items});
  final String label;
  final List<MovieEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, i) => _MovieCard(movie: items[i]),
          ),
        ),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});
  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: movie.thumbnail != null
                  ? Image.network(
                      movie.thumbnail!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, e, s) =>
                          const _ThumbnailPlaceholder(height: 0),
                      loadingBuilder: (context, child, chunk) =>
                          chunk == null ? child : const _ThumbnailPlaceholder(height: 0),
                    )
                  : const _ThumbnailPlaceholder(height: 0),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height == 0 ? null : height,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.movie_outlined,
        color: AppColors.textHint,
        size: 32,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'errors.network'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'general.try_again'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 156,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.read<HomeBloc>().add(HomeLoad()),
                child: Text('general.retry'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
