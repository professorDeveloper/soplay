import 'package:equatable/equatable.dart';

class ShortEntity extends Equatable {
  const ShortEntity({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnail,
    required this.provider,
    required this.contentUrl,
    required this.contentTitle,
    required this.contentThumbnail,
    required this.likeCount,
    required this.viewCount,
    required this.likedByMe,
    required this.tags,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String videoUrl;
  final String thumbnail;
  final String provider;
  final String contentUrl;
  final String contentTitle;
  final String contentThumbnail;
  final int likeCount;
  final int viewCount;
  final bool likedByMe;
  final List<String> tags;
  final String createdAt;

  ShortEntity copyWith({
    String? id,
    String? title,
    String? videoUrl,
    String? thumbnail,
    String? provider,
    String? contentUrl,
    String? contentTitle,
    String? contentThumbnail,
    int? likeCount,
    int? viewCount,
    bool? likedByMe,
    List<String>? tags,
    String? createdAt,
  }) {
    return ShortEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      provider: provider ?? this.provider,
      contentUrl: contentUrl ?? this.contentUrl,
      contentTitle: contentTitle ?? this.contentTitle,
      contentThumbnail: contentThumbnail ?? this.contentThumbnail,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, title, videoUrl, thumbnail, provider, contentUrl,
        contentTitle, contentThumbnail, likeCount, viewCount,
        likedByMe, tags, createdAt,
      ];
}
