class MediaResolveEntity {
  final String videoUrl;
  final Map<String, String> headers;
  final List<String> languagesAvailable;
  final String? activeLang;

  const MediaResolveEntity({
    required this.videoUrl,
    required this.headers,
    this.languagesAvailable = const [],
    this.activeLang,
  });
}
