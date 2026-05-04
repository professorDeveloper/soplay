part of 'comments_bloc.dart';

abstract class CommentsEvent {
  const CommentsEvent();
}

class CommentsInit extends CommentsEvent {
  final String provider;
  final String contentUrl;
  const CommentsInit({required this.provider, required this.contentUrl});
}

class CommentsRefresh extends CommentsEvent {
  const CommentsRefresh();
}

class CommentsLoadMore extends CommentsEvent {
  const CommentsLoadMore();
}

class CommentsToggleReplies extends CommentsEvent {
  final String commentId;
  const CommentsToggleReplies(this.commentId);
}

class CommentsLoadReplies extends CommentsEvent {
  final String commentId;
  const CommentsLoadReplies(this.commentId);
}

class CommentsCreate extends CommentsEvent {
  final String text;
  final String? parentId;
  const CommentsCreate({required this.text, this.parentId});
}

class CommentsEdit extends CommentsEvent {
  final String id;
  final String text;
  const CommentsEdit({required this.id, required this.text});
}

class CommentsDelete extends CommentsEvent {
  final String id;
  const CommentsDelete(this.id);
}

class CommentsToggleLike extends CommentsEvent {
  final String id;
  const CommentsToggleLike(this.id);
}
