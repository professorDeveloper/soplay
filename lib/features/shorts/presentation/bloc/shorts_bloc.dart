import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/domain/entities/short_like_result.dart';
import 'package:soplay/features/shorts/domain/usecases/get_shorts_usecase.dart';
import 'package:soplay/features/shorts/domain/usecases/increase_short_view_usecase.dart';
import 'package:soplay/features/shorts/domain/usecases/toggle_short_like_usecase.dart';

import 'shorts_event.dart';
import 'shorts_state.dart';

class ShortsBloc extends Bloc<ShortsEvent, ShortsState> {
  ShortsBloc({
    required GetShortsUseCase getShorts,
    required IncreaseShortViewUseCase increaseView,
    required ToggleShortLikeUseCase toggleLike,
    required HiveService hiveService,
  }) : _getShorts = getShorts,
       _increaseView = increaseView,
       _toggleLike = toggleLike,
       _hiveService = hiveService,
       super(const ShortsInitial()) {
    on<ShortsLoad>(_onLoad);
    on<ShortsRefresh>(_onRefresh);
    on<ShortsPageChanged>(_onPageChanged);
    on<ShortsViewed>(_onViewed);
    on<ShortsLikeToggled>(_onLikeToggled);
  }

  final GetShortsUseCase _getShorts;
  final IncreaseShortViewUseCase _increaseView;
  final ToggleShortLikeUseCase _toggleLike;
  final HiveService _hiveService;
  final Set<String> _viewedIds = {};
  int _noticeId = 0;

  Future<void> _onLoad(ShortsLoad event, Emitter<ShortsState> emit) async {
    emit(const ShortsLoading());
    await _load(emit);
  }

  Future<void> _onRefresh(
    ShortsRefresh event,
    Emitter<ShortsState> emit,
  ) async {
    final current = state;
    if (current is ShortsLoaded) {
      emit(current.copyWith(refreshing: true));
    } else {
      emit(const ShortsLoading());
    }
    await _load(emit);
  }

  Future<void> _load(Emitter<ShortsState> emit) async {
    final result = await _getShorts();
    switch (result) {
      case Success<List<ShortEntity>>(:final value):
        emit(ShortsLoaded(items: value));
        if (value.isNotEmpty) add(ShortsViewed(value.first.id));
      case Failure<List<ShortEntity>>(:final error):
        emit(ShortsError(_message(error)));
    }
  }

  void _onPageChanged(ShortsPageChanged event, Emitter<ShortsState> emit) {
    final current = state;
    if (current is! ShortsLoaded) return;
    if (event.index < 0 || event.index >= current.items.length) return;
    emit(current.copyWith(activeIndex: event.index));
    add(ShortsViewed(current.items[event.index].id));
  }

  Future<void> _onViewed(ShortsViewed event, Emitter<ShortsState> emit) async {
    if (event.id.isEmpty || !_viewedIds.add(event.id)) return;
    await _increaseView(event.id);
  }

  Future<void> _onLikeToggled(
    ShortsLikeToggled event,
    Emitter<ShortsState> emit,
  ) async {
    final current = state;
    if (current is! ShortsLoaded) return;
    if (!_hiveService.isLoggedIn) {
      emit(_notice(current, 'Please sign in to like'));
      return;
    }
    if (current.loadingLikeIds.contains(event.id)) return;

    final index = current.items.indexWhere((e) => e.id == event.id);
    if (index < 0) return;

    final item = current.items[index];
    final optimistic = item.copyWith(
      likedByMe: !item.likedByMe,
      likeCount: item.likedByMe
          ? (item.likeCount - 1).clamp(0, 1 << 30).toInt()
          : item.likeCount + 1,
    );
    final loading = {...current.loadingLikeIds, event.id};
    final optimisticItems = _replace(current.items, index, optimistic);
    emit(current.copyWith(items: optimisticItems, loadingLikeIds: loading));

    final result = await _toggleLike(event.id);
    final after = state;
    if (after is! ShortsLoaded) return;
    final idle = {...after.loadingLikeIds}..remove(event.id);

    switch (result) {
      case Success<ShortLikeResult?>(:final value):
        if (value == null) {
          emit(after.copyWith(loadingLikeIds: idle));
          return;
        }
        final i = after.items.indexWhere((e) => e.id == event.id);
        if (i < 0) {
          emit(after.copyWith(loadingLikeIds: idle));
          return;
        }
        emit(
          after.copyWith(
            items: _replace(
              after.items,
              i,
              after.items[i].copyWith(
                likedByMe: value.liked,
                likeCount: value.likeCount,
              ),
            ),
            loadingLikeIds: idle,
          ),
        );
      case Failure<ShortLikeResult?>(:final error):
        emit(
          _notice(
            after.copyWith(items: current.items, loadingLikeIds: idle),
            _message(error),
          ),
        );
    }
  }

  List<ShortEntity> _replace(
    List<ShortEntity> items,
    int index,
    ShortEntity item,
  ) {
    final next = List<ShortEntity>.of(items);
    next[index] = item;
    return next;
  }

  ShortsLoaded _notice(ShortsLoaded state, String message) {
    _noticeId++;
    return state.copyWith(notice: message, noticeId: _noticeId);
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
