import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/notifications/domain/entities/notification_item.dart';
import 'package:soplay/features/notifications/domain/repositories/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc({required this.repository})
      : super(const NotificationsState()) {
    on<NotificationsRefresh>(_onRefresh);
    on<NotificationsLoadMore>(_onLoadMore);
    on<NotificationsMarkRead>(_onMarkRead);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
    on<NotificationsDelete>(_onDelete);
    on<NotificationsUnreadCountChanged>(_onUnreadCountChanged);
  }

  Future<void> _onRefresh(
    NotificationsRefresh event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await repository.list(page: 1, limit: state.limit);
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(
          loading: false,
          items: value.items,
          page: value.page,
          totalPages: value.totalPages,
          total: value.total,
          unread: value.unread,
          error: null,
        ));
      case Failure(:final error):
        emit(state.copyWith(
          loading: false,
          error: error.toString().replaceFirst('Exception: ', ''),
        ));
    }
  }

  Future<void> _onLoadMore(
    NotificationsLoadMore event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.loadingMore) return;
    if (state.page >= state.totalPages) return;
    emit(state.copyWith(loadingMore: true));
    final next = state.page + 1;
    final result = await repository.list(page: next, limit: state.limit);
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(
          loadingMore: false,
          items: [...state.items, ...value.items],
          page: value.page,
          totalPages: value.totalPages,
          total: value.total,
          unread: value.unread,
        ));
      case Failure():
        emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> _onMarkRead(
    NotificationsMarkRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final updated = state.items.map((it) {
      if (it.id != event.id) return it;
      return it.copyWith(read: true, readAt: DateTime.now());
    }).toList();
    final wasUnread = state.items.any((it) => it.id == event.id && !it.read);
    emit(state.copyWith(
      items: updated,
      unread: wasUnread ? (state.unread - 1).clamp(0, 1 << 30) : state.unread,
    ));
    await repository.markRead(event.id);
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final updated = state.items
        .map((it) => it.read ? it : it.copyWith(read: true, readAt: DateTime.now()))
        .toList();
    emit(state.copyWith(items: updated, unread: 0));
    await repository.markAllRead();
  }

  Future<void> _onDelete(
    NotificationsDelete event,
    Emitter<NotificationsState> emit,
  ) async {
    final wasUnread = state.items.any((it) => it.id == event.id && !it.read);
    final filtered = state.items.where((it) => it.id != event.id).toList();
    emit(state.copyWith(
      items: filtered,
      total: (state.total - 1).clamp(0, 1 << 30),
      unread: wasUnread ? (state.unread - 1).clamp(0, 1 << 30) : state.unread,
    ));
    await repository.delete(event.id);
  }

  Future<void> _onUnreadCountChanged(
    NotificationsUnreadCountChanged event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(unread: event.count));
  }
}
