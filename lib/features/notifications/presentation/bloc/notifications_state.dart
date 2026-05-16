part of 'notifications_bloc.dart';

class NotificationsState extends Equatable {
  final List<NotificationItem> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int page;
  final int totalPages;
  final int total;
  final int unread;
  final int limit;

  const NotificationsState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.unread = 0,
    this.limit = 20,
  });

  bool get isEmpty => !loading && items.isEmpty && error == null;
  bool get hasMore => page < totalPages;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? page,
    int? totalPages,
    int? total,
    int? unread,
    int? limit,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      unread: unread ?? this.unread,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props =>
      [items, loading, loadingMore, error, page, totalPages, total, unread, limit];
}
