import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/domain/entities/content_filter_entity.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/home/presentation/bloc/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home_event.dart';
import 'package:soplay/features/home/presentation/bloc/home_state.dart';

String _movieTitle(MovieEntity movie) {
  final title = movie.title.trim();
  if (title.isNotEmpty) return title;

  final slugTitle = _cleanLabel(movie.slug);
  if (slugTitle.isNotEmpty) return slugTitle;

  final externalTitle = _cleanLabel(movie.externalId);
  if (externalTitle.isNotEmpty) return externalTitle;

  final provider = movie.provider.trim();
  return provider.isNotEmpty ? provider : 'Untitled';
}

List<String> _movieMetaLabels(MovieEntity movie) {
  final quality = _primaryQuality(movie);
  return _distinctLabels([
    if (movie.year != null) movie.year.toString(),
    if (movie.rating != null && movie.rating! > 0) '${movie.rating}/10',
    ?quality,
    if (movie.category.trim().isNotEmpty) _cleanLabel(movie.category),
  ]);
}

String? _primaryQuality(MovieEntity movie) {
  final qualities = movie.qualities;
  if (qualities == null || qualities.isEmpty) return null;

  final quality = qualities.first.trim();
  return quality.isEmpty ? null : quality;
}

List<String> _distinctLabels(List<String> labels) {
  final seen = <String>{};
  final result = <String>[];
  for (final label in labels) {
    final cleaned = label.trim();
    if (cleaned.isEmpty) continue;
    final key = cleaned.toLowerCase();
    if (seen.add(key)) result.add(cleaned);
  }
  return result;
}

String _cleanLabel(String value) {
  final source = value.trim().replaceAll(RegExp(r'[-_]+'), ' ');
  if (source.isEmpty) return '';

  return source
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        if (word.length == 1) return word.toUpperCase();
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

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
          return const _HomeSkeleton();
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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _Banner(banners: state.homeData.banner)),
        SliverToBoxAdapter(
          child: _ExploreHeader(
            categories: state.homeData.categories,
            genres: state.homeData.genres,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 108)),
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
  final _controller = PageController(viewportFraction: 0.94);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const _BannerSkeleton();

    return SizedBox(
      height: 470,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final movie = widget.banners[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  index == 0 ? 0 : 6,
                  0,
                  index == widget.banners.length - 1 ? 0 : 6,
                  0,
                ),
                child: _BannerSlide(movie: movie),
              );
            },
          ),
          if (widget.banners.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: _BannerDots(count: widget.banners.length, index: _page),
            ),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.movie});
  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetworkImage(
            url: movie.thumbnail,
            borderRadius: BorderRadius.zero,
            placeholderIcon: Icons.movie_creation_outlined,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x24000000),
                  Color(0x00000000),
                  Color(0xCC181818),
                  AppColors.background,
                ],
                stops: [0.0, 0.34, 0.82, 1.0],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x8A000000),
                  Color(0x22000000),
                  Color(0x00000000),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 26,
            bottom: 54,
            child: _BannerInfo(movie: movie),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MovieMeta(movie: movie),
        const SizedBox(height: 8),
        Text(
          _movieTitle(movie),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
    );
  }
}

class _MovieMeta extends StatelessWidget {
  const _MovieMeta({required this.movie});
  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    final items = _movieMetaLabels(movie);
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: items.take(4).map((item) => _MetaChip(label: item)).toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
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
    return Material(
      color: isPrimary
          ? AppColors.primary
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerDots extends StatelessWidget {
  const _BannerDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dotCount = count > 14 ? 14 : count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotCount, (i) {
        final active = index == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({required this.categories, required this.genres});

  final List<ContentFilterEntity> categories;
  final List<ContentFilterEntity> genres;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && genres.isEmpty) return const SizedBox.shrink();

    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.fromLTRB(14, 18, 0, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            if (categories.isNotEmpty)
              _FilterRail(
                title: 'home.all_categories'.tr(),
                items: categories,
                icon: Icons.grid_view_rounded,
                isGenre: false,
              ),
            if (genres.isNotEmpty)
              _FilterRail(
                title: 'home.genres'.tr(),
                items: genres,
                icon: Icons.local_offer_outlined,
                isGenre: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.title,
    required this.items,
    required this.icon,
    required this.isGenre,
  });

  final String title;
  final List<ContentFilterEntity> items;
  final IconData icon;
  final bool isGenre;

  @override
  Widget build(BuildContext context) {
    final itemCount = items.length > 12 ? 12 : items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 10),
            child: _SectionHeader(title: title),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _FilterChip(
                  label: item.label,
                  icon: icon,
                  onTap: () => context.read<HomeBloc>().add(
                    HomeCollectionLoad(
                      slug: item.slug,
                      title: item.label,
                      isGenre: isGenre,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2B2B2B),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFD5D5D5), size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    required this.url,
    required this.borderRadius,
    required this.placeholderIcon,
  });

  final String? url;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, e, s) =>
                  _ImagePlaceholder(icon: placeholderIcon),
              loadingBuilder: (context, child, chunk) {
                if (chunk == null) return child;
                return _ImagePlaceholder(icon: placeholderIcon);
              },
            )
          : _ImagePlaceholder(icon: placeholderIcon),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Icon(icon, color: AppColors.textHint, size: 32),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _BannerSkeleton()),
        SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 470,
      child: _ImagePlaceholder(icon: Icons.movie_creation_outlined),
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
