import 'package:soplay/features/comments/domain/entities/comment_list.dart';
import 'comment_model.dart';

class CommentListModel extends CommentList {
  const CommentListModel({
    required super.items,
    required super.page,
    required super.totalPages,
    required super.total,
  });

  factory CommentListModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) => CommentModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return CommentListModel(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
