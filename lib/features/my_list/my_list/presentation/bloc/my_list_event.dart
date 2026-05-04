import 'package:equatable/equatable.dart';

sealed class MyListEvent extends Equatable {
  const MyListEvent();

  @override
  List<Object?> get props => [];
}

class MyListLoad extends MyListEvent {
  const MyListLoad();
}

class MyListRefresh extends MyListEvent {
  const MyListRefresh();
}
