import 'video_source_entity.dart';

class MediaResolveEntity {
  final String videoUrl;
  final String? type;
  final Map<String, String> headers;
  final List<VideoSourceEntity> videoSources;
  final List<String> languagesAvailable;
  final String? activeLang;

  const MediaResolveEntity({
    required this.videoUrl,
    required this.headers,
    this.type,
    this.videoSources = const [],
    this.languagesAvailable = const [],
    this.activeLang,
  });
}
