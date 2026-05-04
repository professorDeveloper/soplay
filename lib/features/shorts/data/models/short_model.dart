import 'package:soplay/features/shorts/domain/entities/short_entity.dart';

class ShortModel extends ShortEntity {
  const ShortModel({
    required super.id,
    required super.title,
    required super.description,
    required super.videoUrl,
    required super.thumbnail,
    required super.provider,
    required super.contentUrl,
    required super.contentTitle,
    required super.contentThumbnail,
    required super.author,
    required super.authorAvatar,
    required super.likeCount,
    required super.viewCount,
    required super.likedByMe,
    required super.tags,
  });

  factory ShortModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorMap = author is Map ? author : const {};
    final content = json['content'];
    final contentMap = content is Map ? content : const {};

    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.whereType<String>().toList()
        : const <String>[];

    return ShortModel(
      id: _str(json['id'] ?? json['_id'] ?? json['shortId']),
      title: _str(json['title'] ?? json['caption'] ?? json['name']),
      description: _str(json['description'] ?? json['text']),
      videoUrl: _str(
        json['videoUrl'] ?? json['video'] ?? json['mediaUrl'] ?? json['url'],
      ),
      thumbnail: _str(
        json['thumbnailUrl'] ??
            json['thumbnail'] ??
            json['poster'] ??
            json['image'] ??
            json['cover'],
      ),
      provider: _str(
        json['provider'] ??
            json['contentProvider'] ??
            json['source'] ??
            json['providerId'],
      ),
      contentUrl: _str(
        json['contentUrl'] ??
            json['contentURL'] ??
            json['movieUrl'] ??
            json['detailUrl'] ??
            contentMap['contentUrl'] ??
            contentMap['url'],
      ),
      contentTitle: _str(json['contentTitle'] ?? contentMap['title']),
      contentThumbnail: _str(
        json['contentThumbnail'] ?? contentMap['thumbnail'] ?? contentMap['image'],
      ),
      author: _str(
        json['authorName'] ??
            json['username'] ??
            authorMap['name'] ??
            authorMap['username'] ??
            (author is String ? author : null),
      ),
      authorAvatar: _str(
        json['authorAvatar'] ?? authorMap['avatar'] ?? authorMap['image'],
      ),
      likeCount: _int(json['likeCount'] ?? json['likes']),
      viewCount: _int(json['viewCount'] ?? json['views']),
      likedByMe: _bool(json['likedByMe'] ?? json['isLiked'] ?? json['liked']),
      tags: tags,
    );
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    final raw = v?.toString().toLowerCase();
    return raw == 'true' || raw == '1';
  }
}
