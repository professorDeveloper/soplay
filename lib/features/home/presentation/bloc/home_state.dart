import 'package:equatable/equatable.dart';

import '../../domain/entities/home_data_entity.dart';

class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeLoaded extends HomeState {
  final HomeDataEntity homeData;

  HomeLoaded(this.homeData);

  @override
  List<Object?> get props => [homeData];
}
