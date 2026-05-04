import 'package:equatable/equatable.dart';

sealed class ShortsEvent extends Equatable {
  const ShortsEvent();

  @override
  List<Object?> get props => [];
}

class ShortsLoad extends ShortsEvent {
  const ShortsLoad();
}

class ShortsRefresh extends ShortsEvent {
  const ShortsRefresh();
}

class ShortsLoadMore extends ShortsEvent {
  const ShortsLoadMore();
}

class ShortsPageChanged extends ShortsEvent {
  const ShortsPageChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class ShortsViewed extends ShortsEvent {
  const ShortsViewed(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ShortsLikeToggled extends ShortsEvent {
  const ShortsLikeToggled(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
