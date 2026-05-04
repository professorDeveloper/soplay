import 'package:equatable/equatable.dart';

sealed class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

class FavoriteGuest extends FavoriteState {
  const FavoriteGuest();
}

class FavoriteReady extends FavoriteState {
  const FavoriteReady({required this.isInList, this.isLoading = false});

  final bool isInList;
  final bool isLoading;

  FavoriteReady copyWith({bool? isInList, bool? isLoading}) => FavoriteReady(
    isInList: isInList ?? this.isInList,
    isLoading: isLoading ?? this.isLoading,
  );

  @override
  List<Object?> get props => [isInList, isLoading];
}
