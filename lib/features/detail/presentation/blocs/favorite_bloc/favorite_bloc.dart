import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';
import 'package:soplay/features/my_list/domain/entities/my_list_failure.dart';
import 'package:soplay/features/my_list/domain/usecases/add_favorite_usecase.dart';
import 'package:soplay/features/my_list/domain/usecases/get_favorites_usecase.dart';
import 'package:soplay/features/my_list/domain/usecases/remove_favorite_usecase.dart';

import 'favorite_event.dart';
import 'favorite_state.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  FavoriteBloc({
    required GetFavoritesUseCase getFavorites,
    required AddFavoriteUseCase addFavorite,
    required RemoveFavoriteUseCase removeFavorite,
    required HiveService hiveService,
  }) : _getFavorites = getFavorites,
       _addFavorite = addFavorite,
       _removeFavorite = removeFavorite,
       _hiveService = hiveService,
       super(const FavoriteInitial()) {
    on<FavoriteLoad>(_onLoad);
    on<FavoriteToggle>(_onToggle);
  }

  final GetFavoritesUseCase _getFavorites;
  final AddFavoriteUseCase _addFavorite;
  final RemoveFavoriteUseCase _removeFavorite;
  final HiveService _hiveService;

  Future<void> _onLoad(FavoriteLoad event, Emitter<FavoriteState> emit) async {
    if (!_hiveService.isLoggedIn) {
      emit(const FavoriteGuest());
      return;
    }

    final result = await _getFavorites();
    switch (result) {
      case Success(:final value):
        final isInList = value.any((e) => e.contentUrl == event.contentUrl);
        emit(FavoriteReady(isInList: isInList));
      case Failure(:final error):
        if (error is MyListUnauthorizedException) {
          emit(const FavoriteGuest());
        } else {
          emit(const FavoriteReady(isInList: false));
        }
    }
  }

  Future<void> _onToggle(
    FavoriteToggle event,
    Emitter<FavoriteState> emit,
  ) async {
    final current = state;
    if (!_hiveService.isLoggedIn) {
      emit(const FavoriteGuest());
      return;
    }
    if (current is! FavoriteReady || current.isLoading) return;

    emit(current.copyWith(isLoading: true));

    if (current.isInList) {
      final result = await _removeFavorite(event.contentUrl);
      switch (result) {
        case Success():
          emit(current.copyWith(isInList: false, isLoading: false));
        case Failure():
          emit(current.copyWith(isLoading: false));
      }
    } else {
      final result = await _addFavorite(
        FavoriteEntity(
          contentUrl: event.contentUrl,
          provider: event.provider,
          title: event.title,
          thumbnail: event.thumbnail,
        ),
      );
      switch (result) {
        case Success():
          emit(current.copyWith(isInList: true, isLoading: false));
        case Failure():
          emit(current.copyWith(isLoading: false));
      }
    }
  }
}
