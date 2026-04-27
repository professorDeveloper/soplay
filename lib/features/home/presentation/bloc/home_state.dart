import 'package:equatable/equatable.dart';

import '../../domain/entities/home_data_entity.dart';
import '../../domain/entities/movie.dart';

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
  final String? collectionTitle;
  final List<MovieEntity> collectionItems;
  final bool collectionLoading;

  HomeLoaded(
    this.homeData, {
    this.collectionTitle,
    this.collectionItems = const [],
    this.collectionLoading = false,
  });

  HomeLoaded copyWith({
    String? collectionTitle,
    List<MovieEntity>? collectionItems,
    bool? collectionLoading,
  }) {
    return HomeLoaded(
      homeData,
      collectionTitle: collectionTitle ?? this.collectionTitle,
      collectionItems: collectionItems ?? this.collectionItems,
      collectionLoading: collectionLoading ?? this.collectionLoading,
    );
  }

  @override
  List<Object?> get props => [
    homeData,
    collectionTitle,
    collectionItems,
    collectionLoading,
  ];
}
