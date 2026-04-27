class ContentFilterEntity {
  final String provider;
  final String slug;
  final String path;
  final String url;

  const ContentFilterEntity({
    required this.provider,
    required this.slug,
    required this.path,
    required this.url,
  });

  String get label {
    final source = path.isNotEmpty ? path : slug;
    return source
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
