import 'package:soplay/features/shorts/domain/entities/short_entity.dart';

class ShortModel extends ShortEntity {
  const ShortModel({
    required super.id,
    required super.title,
    required super.videoUrl,
    required super.thumbnail,
    required super.provider,
    required super.contentUrl,
    required super.contentTitle,
    required super.contentThumbnail,
    required super.likeCount,
    required super.viewCount,
    required super.likedByMe,
    required super.tags,
    required super.createdAt,
  });

  factory ShortModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.whereType<String>().toList()
        : const <String>[];

    final content = json['content'];
    final contentMap = content is Map ? content : const {};

    return ShortModel(
      id: _str(json['_id'] ?? json['id']),
      title: _str(json['title']),
      videoUrl: _str(json['videoUrl']),
      thumbnail: _str(json['thumbnailUrl'] ?? json['thumbnail']),
      provider: _str(json['provider']),
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
        json['contentThumbnail'] ?? contentMap['thumbnail'],
      ),
      viewCount: _int(json['views'] ?? json['viewCount']),
      likeCount: _int(json['likeCount'] ?? json['likes']),
      likedByMe: _bool(json['likedByMe'] ?? json['isLiked']),
      tags: tags,
      createdAt: _str(json['createdAt']),
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
