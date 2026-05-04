import 'package:equatable/equatable.dart';

class ShortEntity extends Equatable {
  const ShortEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnail,
    required this.provider,
    required this.contentUrl,
    required this.contentTitle,
    required this.contentThumbnail,
    required this.author,
    required this.authorAvatar,
    required this.likeCount,
    required this.viewCount,
    required this.likedByMe,
    required this.tags,
  });

  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnail;
  final String provider;
  final String contentUrl;
  final String contentTitle;
  final String contentThumbnail;
  final String author;
  final String authorAvatar;
  final int likeCount;
  final int viewCount;
  final bool likedByMe;
  final List<String> tags;

  ShortEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnail,
    String? provider,
    String? contentUrl,
    String? contentTitle,
    String? contentThumbnail,
    String? author,
    String? authorAvatar,
    int? likeCount,
    int? viewCount,
    bool? likedByMe,
    List<String>? tags,
  }) {
    return ShortEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      provider: provider ?? this.provider,
      contentUrl: contentUrl ?? this.contentUrl,
      contentTitle: contentTitle ?? this.contentTitle,
      contentThumbnail: contentThumbnail ?? this.contentThumbnail,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        videoUrl,
        thumbnail,
        provider,
        contentUrl,
        contentTitle,
        contentThumbnail,
        author,
        authorAvatar,
        likeCount,
        viewCount,
        likedByMe,
        tags,
      ];
}
