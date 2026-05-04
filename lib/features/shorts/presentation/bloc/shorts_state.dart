import 'package:equatable/equatable.dart';
import 'package:soplay/features/shorts/domain/entities/short_entity.dart';

sealed class ShortsState extends Equatable {
  const ShortsState();

  @override
  List<Object?> get props => [];
}

class ShortsInitial extends ShortsState {
  const ShortsInitial();
}

class ShortsLoading extends ShortsState {
  const ShortsLoading();
}

class ShortsLoaded extends ShortsState {
  final List<ShortEntity> items;
  final int activeIndex;
  final Set<String> loadingLikeIds;
  final String? notice;
  final int noticeId;
  final bool refreshing;

  const ShortsLoaded({
    required this.items,
    this.activeIndex = 0,
    this.loadingLikeIds = const {},
    this.notice,
    this.noticeId = 0,
    this.refreshing = false,
  });

  ShortsLoaded copyWith({
    List<ShortEntity>? items,
    int? activeIndex,
    Set<String>? loadingLikeIds,
    String? notice,
    int? noticeId,
    bool? refreshing,
  }) {
    return ShortsLoaded(
      items: items ?? this.items,
      activeIndex: activeIndex ?? this.activeIndex,
      loadingLikeIds: loadingLikeIds ?? this.loadingLikeIds,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
      refreshing: refreshing ?? this.refreshing,
    );
  }

  @override
  List<Object?> get props => [
    items,
    activeIndex,
    loadingLikeIds,
    notice,
    noticeId,
    refreshing,
  ];
}

class ShortsError extends ShortsState {
  final String message;

  const ShortsError(this.message);

  @override
  List<Object?> get props => [message];
}
