part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => const [];
}

class NotificationsRefresh extends NotificationsEvent {
  const NotificationsRefresh();
}

class NotificationsLoadMore extends NotificationsEvent {
  const NotificationsLoadMore();
}

class NotificationsMarkRead extends NotificationsEvent {
  final String id;
  const NotificationsMarkRead(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllRead extends NotificationsEvent {
  const NotificationsMarkAllRead();
}

class NotificationsDelete extends NotificationsEvent {
  final String id;
  const NotificationsDelete(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsUnreadCountChanged extends NotificationsEvent {
  final int count;
  const NotificationsUnreadCountChanged(this.count);
  @override
  List<Object?> get props => [count];
}
