import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/entities/movie.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';
import 'package:soplay/features/search/domain/usecases/genre_usecase.dart';
import 'package:soplay/features/search/domain/usecases/search_usecase.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchUseCase _searchUseCase;
  final GenreUseCase _genreUseCase;

  Timer? _debounce;

  SearchBloc({
    required SearchUseCase searchUseCase,
    required GenreUseCase genreUseCase,
  })  : _searchUseCase = searchUseCase,
        _genreUseCase = genreUseCase,
        super(const SearchInitial()) {
    on<SearchLoad>(_onLoad);
    on<SearchQueryChanged>(_onQueryChanged);
    on<_SearchExecute>(_onExecute);
    on<SearchLoadMore>(_onLoadMore);
    on<SearchByGenre>(_onByGenre);
  }

  Future<void> _onLoad(SearchLoad event, Emitter<SearchState> emit) async {
    emit(const SearchGenresLoading());
    final result = await _genreUseCase();
    if (result.isSuccess) {
      emit(SearchGenresLoaded(result.getOrNull()!));
    } else {
      emit(SearchError(result.getErrorOrNull()!.toString()));
    }
  }

  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    _debounce?.cancel();
    final q = event.query.trim();
    if (q.isEmpty) {
      add(const SearchLoad());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!isClosed) add(_SearchExecute(q));
    });
  }

  Future<void> _onExecute(_SearchExecute event, Emitter<SearchState> emit) async {
    emit(const SearchLoading());
    final result = await _searchUseCase(event.query);
    if (result.isSuccess) {
      final data = result.getOrNull()!;
      emit(SearchLoaded(
        query: event.query,
        items: data.items,
        page: data.page,
        totalPages: data.totalPages,
      ));
    } else {
      emit(SearchError(result.getErrorOrNull()!.toString()));
    }
  }

  Future<void> _onLoadMore(SearchLoadMore event, Emitter<SearchState> emit) async {
    final current = state;
    if (current is! SearchLoaded || current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.page + 1;

    final Result<dynamic> result = current.query.isNotEmpty
        ? await _searchUseCase(current.query, page: nextPage)
        : await _genreUseCase.callByGenre(current.genre, page: nextPage);

    if (result.isSuccess) {
      final data = result.getOrNull()!;
      emit(current.copyWith(
        items: [...current.items, ...data.items],
        page: data.page,
        totalPages: data.totalPages,
        isLoadingMore: false,
      ));
    } else {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onByGenre(SearchByGenre event, Emitter<SearchState> emit) async {
    emit(const SearchLoading());
    final result = await _genreUseCase.callByGenre(event.genre);
    if (result.isSuccess) {
      final data = result.getOrNull()!;
      emit(SearchLoaded(
        genre: event.genre,
        items: data.items,
        page: data.page,
        totalPages: data.totalPages,
      ));
    } else {
      emit(SearchError(result.getErrorOrNull()!.toString()));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
