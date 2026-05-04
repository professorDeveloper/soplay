import 'comment_entity.dart';

class CommentList {
  final List<CommentEntity> items;
  final int page;
  final int totalPages;
  final int total;

  const CommentList({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}
