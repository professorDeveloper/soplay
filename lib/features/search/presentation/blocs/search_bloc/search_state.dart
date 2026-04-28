part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchGenresLoading extends SearchState {
  const SearchGenresLoading();
}

class SearchGenresLoaded extends SearchState {
  const SearchGenresLoaded(this.genres);
  final List<GenreEntity> genres;
  @override
  List<Object?> get props => [genres];
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  const SearchLoaded({
    required this.items,
    required this.page,
    required this.totalPages,
    this.query = '',
    this.genre = '',
    this.isLoadingMore = false,
  });

  final List<MovieEntity> items;
  final int page;
  final int totalPages;
  final String query;
  final String genre;
  final bool isLoadingMore;

  bool get hasMore => page < totalPages;

  SearchLoaded copyWith({
    List<MovieEntity>? items,
    int? page,
    int? totalPages,
    String? query,
    String? genre,
    bool? isLoadingMore,
  }) =>
      SearchLoaded(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        query: query ?? this.query,
        genre: genre ?? this.genre,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [items, page, totalPages, query, genre, isLoadingMore];
}

class SearchError extends SearchState {
  const SearchError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
