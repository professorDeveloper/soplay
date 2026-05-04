import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';
import 'package:soplay/features/shorts/domain/entities/short_like_result.dart';
import 'package:soplay/features/shorts/domain/entities/shorts_feed_result.dart';
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
    on<ShortsLoadMore>(_onLoadMore);
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
  bool _signInNoticeShown = false;
  DateTime? _lastNoticeTime;

  Future<void> _onLoad(ShortsLoad event, Emitter<ShortsState> emit) async {
    emit(const ShortsLoading());
    await _loadFeed(emit);
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
    _viewedIds.clear();
    _signInNoticeShown = false;
    await _loadFeed(emit);
  }

  Future<void> _onLoadMore(
    ShortsLoadMore event,
    Emitter<ShortsState> emit,
  ) async {
    final current = state;
    if (current is! ShortsLoaded) return;
    if (!current.hasMore || current.loadingMore) return;

    emit(current.copyWith(loadingMore: true));

    final result = await _getShorts(cursor: current.nextCursor);
    switch (result) {
      case Success<ShortsFeedResult>(:final value):
        emit(current.copyWith(
          items: [...current.items, ...value.items],
          nextCursor: value.nextCursor,
          hasMore: value.hasMore,
          loadingMore: false,
        ));
      case Failure<ShortsFeedResult>():
        emit(current.copyWith(loadingMore: false));
    }
  }

  Future<void> _loadFeed(Emitter<ShortsState> emit) async {
    final result = await _getShorts();
    switch (result) {
      case Success<ShortsFeedResult>(:final value):
        emit(ShortsLoaded(
          items: value.items,
          nextCursor: value.nextCursor,
          hasMore: value.hasMore,
        ));
        if (value.items.isNotEmpty) add(ShortsViewed(value.items.first.id));
      case Failure<ShortsFeedResult>(:final error):
        emit(ShortsError(_message(error)));
    }
  }

  void _onPageChanged(
    ShortsPageChanged event,
    Emitter<ShortsState> emit,
  ) {
    final current = state;
    if (current is! ShortsLoaded) return;
    if (event.index < 0 || event.index >= current.items.length) return;

    emit(current.copyWith(activeIndex: event.index));
    add(ShortsViewed(current.items[event.index].id));

    if (current.hasMore &&
        !current.loadingMore &&
        event.index >= current.items.length - 3) {
      add(const ShortsLoadMore());
    }
  }

  Future<void> _onViewed(
    ShortsViewed event,
    Emitter<ShortsState> emit,
  ) async {
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
      if (!_signInNoticeShown) {
        _signInNoticeShown = true;
        emit(_notice(current, 'Please sign in to like'));
      }
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
    emit(
      current.copyWith(
        items: _replace(current.items, index, optimistic),
        loadingLikeIds: loading,
      ),
    );

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
        emit(after.copyWith(
          items: _replace(
            after.items,
            i,
            after.items[i].copyWith(
              likedByMe: value.liked,
              likeCount: value.likeCount,
            ),
          ),
          loadingLikeIds: idle,
        ));
      case Failure<ShortLikeResult?>():
        emit(after.copyWith(items: current.items, loadingLikeIds: idle));
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
    final now = DateTime.now();
    if (_lastNoticeTime != null &&
        now.difference(_lastNoticeTime!).inSeconds < 3) {
      return state;
    }
    _lastNoticeTime = now;
    _noticeId++;
    return state.copyWith(notice: message, noticeId: _noticeId);
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
