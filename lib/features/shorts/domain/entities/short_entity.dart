import 'package:equatable/equatable.dart';

class ShortEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnail;
  final String author;
  final String authorAvatar;
  final int likeCount;
  final int viewCount;
  final bool likedByMe;

  const ShortEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnail,
    required this.author,
    required this.authorAvatar,
    required this.likeCount,
    required this.viewCount,
    required this.likedByMe,
  });

  ShortEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnail,
    String? author,
    String? authorAvatar,
    int? likeCount,
    int? viewCount,
    bool? likedByMe,
  }) {
    return ShortEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    videoUrl,
    thumbnail,
    author,
    authorAvatar,
    likeCount,
    viewCount,
    likedByMe,
  ];
}
