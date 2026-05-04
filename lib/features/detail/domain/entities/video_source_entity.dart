class VideoSourceEntity {
  final String quality;
  final String videoUrl;
  final bool isDefault;
  final bool accessible;

  const VideoSourceEntity({
    required this.quality,
    required this.videoUrl,
    required this.isDefault,
    required this.accessible,
  });
}
