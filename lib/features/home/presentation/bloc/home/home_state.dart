import 'package:equatable/equatable.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';

import '../../../domain/entities/home_data_entity.dart';
import '../../../domain/entities/movie.dart';

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
  final List<GenreEntity> genres;
  final bool collectionLoading;

  HomeLoaded(
    this.genres,
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
      genres,
      homeData,
      collectionTitle: collectionTitle ?? this.collectionTitle,
      collectionItems: collectionItems ?? this.collectionItems,
      collectionLoading: collectionLoading ?? this.collectionLoading,
    );
  }

  @override
  List<Object?> get props => [
    genres,
    homeData,
    collectionTitle,
    collectionItems,
    collectionLoading,
  ];
}
