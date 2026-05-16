class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.data,
    required this.read,
    required this.readAt,
    required this.createdAt,
  });

  NotificationItem copyWith({bool? read, DateTime? readAt}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationList {
  final List<NotificationItem> items;
  final int page;
  final int totalPages;
  final int total;
  final int unread;

  const NotificationList({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.unread,
  });
}
