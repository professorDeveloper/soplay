import 'package:soplay/features/shorts/domain/entities/short_entity.dart';

class ShortModel extends ShortEntity {
  const ShortModel({
    required super.id,
    required super.title,
    required super.description,
    required super.videoUrl,
    required super.thumbnail,
    required super.author,
    required super.authorAvatar,
    required super.likeCount,
    required super.viewCount,
    required super.likedByMe,
  });

  factory ShortModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorMap = author is Map ? author : const {};
    return ShortModel(
      id: _string(json['id'] ?? json['_id'] ?? json['shortId']),
      title: _string(json['title'] ?? json['caption'] ?? json['name']),
      description: _string(json['description'] ?? json['text']),
      videoUrl: _string(
        json['videoUrl'] ?? json['video'] ?? json['mediaUrl'] ?? json['url'],
      ),
      thumbnail: _string(
        json['thumbnail'] ?? json['poster'] ?? json['image'] ?? json['cover'],
      ),
      author: _string(
        json['authorName'] ??
            json['username'] ??
            authorMap['name'] ??
            authorMap['username'] ??
            (author is String ? author : null),
      ),
      authorAvatar: _string(
        json['authorAvatar'] ?? authorMap['avatar'] ?? authorMap['image'],
      ),
      likeCount: _int(json['likeCount'] ?? json['likes']),
      viewCount: _int(json['viewCount'] ?? json['views']),
      likedByMe: _bool(json['likedByMe'] ?? json['isLiked'] ?? json['liked']),
    );
  }

  static String _string(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().toLowerCase();
    return raw == 'true' || raw == '1';
  }
}
