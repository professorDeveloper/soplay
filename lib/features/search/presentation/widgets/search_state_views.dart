import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/search/presentation/blocs/search_bloc.dart';

class SearchContentView extends StatelessWidget {
  const SearchContentView({
    super.key,
    required this.state,
    required this.scrollController,
    required this.topPad,
    required this.bottomPad,
    required this.onRetry,
  });

  final SearchState state;
  final ScrollController scrollController;
  final double topPad;
  final double bottomPad;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final currentState = state;
    if (currentState is SearchLoaded) {
      return _SearchResultsView(
        state: currentState,
        scrollController: scrollController,
        topPad: topPad,
        bottomPad: bottomPad,
      );
    }
    if (currentState is SearchLoading) {
      return _SearchLoadingView(topPad: topPad);
    }
    if (currentState is SearchError) {
      return _SearchErrorView(topPad: topPad, onRetry: onRetry);
    }
    return _SearchPlaceholder(topPad: topPad);
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({required this.topPad});

  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.textHint.withValues(alpha: 0.45),
              size: 68,
            ),
            const SizedBox(height: 16),
            Text(
              'search.hint'.tr(),
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView({required this.topPad});

  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.state,
    required this.scrollController,
    required this.topPad,
    required this.bottomPad,
  });

  final SearchLoaded state;
  final ScrollController scrollController;
  final double topPad;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPad),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: AppColors.textHint,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                'search.no_results_for'.tr(
                  namedArgs: {
                    'query': state.query.isNotEmpty ? state.query : state.genre,
                  },
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _SearchMovieCard(movie: state.items[i]),
              childCount: state.items.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
          ),
        ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPad + 90)),
      ],
    );
  }
}

class _SearchMovieCard extends StatelessWidget {
  const _SearchMovieCard({required this.movie});

  final MovieEntity movie;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          movie.thumbnail != null
              ? Image.network(
                  movie.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _placeholder(),
                )
              : _placeholder(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(6, 22, 6, 6),
              child: Text(
                movie.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (movie.rating != null)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.rating,
                      size: 9,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${movie.rating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.movie_rounded,
        color: AppColors.textHint,
        size: 32,
      ),
    );
  }
}

class _SearchErrorView extends StatelessWidget {
  const _SearchErrorView({required this.topPad, required this.onRetry});

  final double topPad;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textHint,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                'errors.network'.tr(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'general.retry'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
