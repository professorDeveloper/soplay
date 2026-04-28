import 'package:equatable/equatable.dart';

class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeLoad extends HomeEvent {
  final bool silent;

  HomeLoad({this.silent = false});

  @override
  List<Object?> get props => [silent];
}
