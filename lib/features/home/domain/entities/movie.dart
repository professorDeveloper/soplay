class MovieEntity {
  final String externalId;
  final String title;
  final String description;
  final String slug;
  final String url;
  final String provider;
  final String? thumbnail;
  final int? year;
  final int? rating;
  final List<String>? qualities;
  final String category;

  MovieEntity({
    required this.externalId,
    required this.title,
    required this.description,
    required this.slug,
    required this.url,
    required this.provider,
    required this.thumbnail,
    required this.year,
    required this.rating,
    required this.qualities,
    required this.category,
  });
}
