import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';
import 'package:soplay/features/search/presentation/blocs/search_bloc/search_bloc.dart';
import 'package:soplay/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:soplay/features/search/presentation/widgets/search_header.dart';
import 'package:soplay/features/search/presentation/widgets/search_state_views.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>()..add(const SearchLoad()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scrollController = ScrollController();
  final _blurProgress = ValueNotifier<double>(0);

  List<GenreEntity> _cachedGenres = [];
  SearchFilterSelection _filter = const SearchFilterSelection();

  bool get _hasActiveFilter => _filter.hasActiveFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scrollController.dispose();
    _blurProgress.dispose();
    super.dispose();
  }

  void _onScroll() {
    final next = (_scrollController.offset / 80).clamp(0.0, 1.0);
    if ((next - _blurProgress.value).abs() >= 0.015) {
      _blurProgress.value = next;
    }

    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<SearchBloc>().add(const SearchLoadMore());
    }
  }

  void _clearSearch() {
    _controller.clear();
    context.read<SearchBloc>().add(const SearchQueryChanged(''));
  }

  void _openFilter() {
    final bloc = context.read<SearchBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SearchFilterSheet(
        initialSelection: _filter,
        genres: _cachedGenres,
        onApply: (selection) {
          if (!mounted) return;
          setState(() => _filter = selection);

          final query = _controller.text.trim();
          if (selection.genre.isNotEmpty && query.isEmpty) {
            bloc.add(SearchByGenre(selection.genre));
          } else if (!selection.hasActiveFilter && query.isEmpty) {
            bloc.add(const SearchLoad());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final headerHeight = topPad + 128.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          BlocConsumer<SearchBloc, SearchState>(
            listener: (context, state) {
              if (state is SearchGenresLoaded) {
                _cachedGenres = state.genres;
              }
            },
            builder: (context, state) => SearchContentView(
              state: state,
              scrollController: _scrollController,
              topPad: headerHeight,
              bottomPad: bottomPad,
              onRetry: () => context.read<SearchBloc>().add(const SearchLoad()),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _blurProgress,
            builder: (context, progress, _) => SearchStickyHeader(
              progress: progress,
              topPad: topPad,
              controller: _controller,
              focus: _focus,
              hasActiveFilter: _hasActiveFilter,
              onFilterTap: _openFilter,
              onQueryChanged: (q) =>
                  context.read<SearchBloc>().add(SearchQueryChanged(q)),
              onClear: _clearSearch,
            ),
          ),
        ],
      ),
    );
  }
}
