class FavoriteEntity {
  final String provider;
  final String contentUrl;
  final String title;
  final String thumbnail;
  final String description;

  const FavoriteEntity({
    required this.provider,
    required this.contentUrl,
    required this.title,
    required this.thumbnail,
    this.description = '',
  });
}
