import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/my_list/domain/entities/favorite_entity.dart';
import 'package:soplay/features/my_list/domain/usecases/add_favorite_usecase.dart';
import 'package:soplay/features/my_list/domain/usecases/remove_favorite_usecase.dart';

import 'favorite_event.dart';
import 'favorite_state.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  FavoriteBloc({
    required AddFavoriteUseCase addFavorite,
    required RemoveFavoriteUseCase removeFavorite,
    required HiveService hiveService,
  }) : _addFavorite = addFavorite,
       _removeFavorite = removeFavorite,
       _hiveService = hiveService,
       super(const FavoriteInitial()) {
    on<FavoriteLoad>(_onLoad);
    on<FavoriteToggle>(_onToggle);
  }

  final AddFavoriteUseCase _addFavorite;
  final RemoveFavoriteUseCase _removeFavorite;
  final HiveService _hiveService;

  Future<void> _onLoad(FavoriteLoad event, Emitter<FavoriteState> emit) async {
    if (!_hiveService.isLoggedIn) {
      emit(const FavoriteGuest());
      return;
    }

    emit(FavoriteReady(isInList: event.isFavorited ?? false));
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

    final nextIsInList = !current.isInList;
    emit(current.copyWith(isInList: nextIsInList, isLoading: true));

    if (current.isInList) {
      final result = await _removeFavorite(event.contentUrl);
      switch (result) {
        case Success():
          emit(FavoriteReady(isInList: nextIsInList));
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
          emit(FavoriteReady(isInList: nextIsInList));
        case Failure():
          emit(current.copyWith(isLoading: false));
      }
    }
  }
}
