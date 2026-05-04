import 'package:soplay/features/shorts/domain/entities/short_like_result.dart';

class ShortLikeResultModel extends ShortLikeResult {
  const ShortLikeResultModel({required super.liked, required super.likeCount});

  factory ShortLikeResultModel.fromJson(Map<String, dynamic> json) {
    return ShortLikeResultModel(
      liked: _bool(json['liked'] ?? json['likedByMe'] ?? json['isLiked']),
      likeCount: _int(json['likeCount'] ?? json['likes']),
    );
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
