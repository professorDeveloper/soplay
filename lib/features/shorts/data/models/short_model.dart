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

    return ShortModel(
      id: _str(json['_id']),
      title: _str(json['title']),
      videoUrl: _str(json['videoUrl']),
      thumbnail: _str(json['thumbnailUrl']),
      provider: _str(json['provider']),
      contentUrl: _str(json['contentUrl']),
      contentTitle: _str(json['contentTitle']),
      contentThumbnail: _str(json['contentThumbnail']),
      viewCount: _int(json['views']),
      likeCount: _int(json['likeCount']),
      likedByMe: _bool(json['likedByMe']),
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
