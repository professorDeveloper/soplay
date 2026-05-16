import 'package:soplay/features/notifications/domain/entities/notification_item.dart';

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.imageUrl,
    required super.data,
    required super.read,
    required super.readAt,
    required super.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw is String) return DateTime.tryParse(raw)?.toLocal();
      return null;
    }

    final dataRaw = json['data'];
    final data = dataRaw is Map
        ? dataRaw.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    return NotificationItemModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      data: data,
      read: json['read'] as bool? ?? false,
      readAt: parseDate(json['readAt']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class NotificationListModel extends NotificationList {
  const NotificationListModel({
    required super.items,
    required super.page,
    required super.totalPages,
    required super.total,
    required super.unread,
  });

  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => NotificationItemModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
    return NotificationListModel(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }
}
