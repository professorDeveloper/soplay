part of 'search_bloc.dart';

abstract class SearchEvent {
  const SearchEvent();
}

class SearchLoad extends SearchEvent {
  const SearchLoad();
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final String query;
}

class _SearchExecute extends SearchEvent {
  const _SearchExecute(this.query);
  final String query;
}

class SearchLoadMore extends SearchEvent {
  const SearchLoadMore();
}

class SearchByGenre extends SearchEvent {
  const SearchByGenre(this.genre);
  final String genre;
}
