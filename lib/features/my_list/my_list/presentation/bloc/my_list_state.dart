import 'package:equatable/equatable.dart';
import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';

sealed class MyListState extends Equatable {
  const MyListState();

  @override
  List<Object?> get props => [];
}

class MyListInitial extends MyListState {
  const MyListInitial();
}

class MyListLoading extends MyListState {
  const MyListLoading();
}

class MyListLoaded extends MyListState {
  final List<FavoriteEntity> items;
  final bool refreshing;

  const MyListLoaded({required this.items, this.refreshing = false});

  MyListLoaded copyWith({List<FavoriteEntity>? items, bool? refreshing}) {
    return MyListLoaded(
      items: items ?? this.items,
      refreshing: refreshing ?? this.refreshing,
    );
  }

  @override
  List<Object?> get props => [items, refreshing];
}

class MyListUnauthorized extends MyListState {
  const MyListUnauthorized();
}

class MyListError extends MyListState {
  final String message;

  const MyListError(this.message);

  @override
  List<Object?> get props => [message];
}
