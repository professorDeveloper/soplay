part of 'comments_bloc.dart';

class CommentsState {
  final bool loading;
  final bool refreshing;
  final bool loadingMore;
  final bool submitting;
  final List<CommentEntity> items;
  final int page;
  final int totalPages;
  final int total;
  final Set<String> expandedIds;
  final Map<String, List<CommentEntity>> repliesByParent;
  final Set<String> repliesLoading;
  final String? error;

  const CommentsState({
    required this.loading,
    required this.refreshing,
    required this.loadingMore,
    required this.submitting,
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.expandedIds,
    required this.repliesByParent,
    required this.repliesLoading,
    required this.error,
  });

  const CommentsState.initial()
      : loading = false,
        refreshing = false,
        loadingMore = false,
        submitting = false,
        items = const [],
        page = 1,
        totalPages = 1,
        total = 0,
        expandedIds = const <String>{},
        repliesByParent = const <String, List<CommentEntity>>{},
        repliesLoading = const <String>{},
        error = null;

  bool get hasMore => page < totalPages;

  CommentsState copyWith({
    bool? loading,
    bool? refreshing,
    bool? loadingMore,
    bool? submitting,
    List<CommentEntity>? items,
    int? page,
    int? totalPages,
    int? total,
    Set<String>? expandedIds,
    Map<String, List<CommentEntity>>? repliesByParent,
    Set<String>? repliesLoading,
    Object? error = _sentinel,
  }) =>
      CommentsState(
        loading: loading ?? this.loading,
        refreshing: refreshing ?? this.refreshing,
        loadingMore: loadingMore ?? this.loadingMore,
        submitting: submitting ?? this.submitting,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        expandedIds: expandedIds ?? this.expandedIds,
        repliesByParent: repliesByParent ?? this.repliesByParent,
        repliesLoading: repliesLoading ?? this.repliesLoading,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}

const Object _sentinel = Object();
