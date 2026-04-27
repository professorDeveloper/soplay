import 'package:soplay/features/home/domain/entities/movie.dart';

String movieTitle(MovieEntity movie) {
  final title = movie.title.trim();
  if (title.isNotEmpty) return title;
  final slugTitle = cleanLabel(movie.slug);
  if (slugTitle.isNotEmpty) return slugTitle;
  final externalTitle = cleanLabel(movie.externalId);
  if (externalTitle.isNotEmpty) return externalTitle;
  final provider = movie.provider.trim();
  return provider.isNotEmpty ? provider : 'Untitled';
}

String movieDescription(MovieEntity movie) {
  return '${movie.title.trim()}${movie.rating}/10${movie.year} ${movie.description.trim()}';
}

List<String> movieMetaLabels(MovieEntity movie) {
  final quality = primaryQuality(movie);
  return _distinctLabels([
    if (movie.year != null) movie.year.toString(),
    if (movie.rating != null && movie.rating! > 0) '${movie.rating}/10',
    ?quality,
    if (movie.category.trim().isNotEmpty) cleanLabel(movie.category),
  ]);
}

String? primaryQuality(MovieEntity movie) {
  final qualities = movie.qualities;
  if (qualities == null || qualities.isEmpty) return null;
  final quality = qualities.first.trim();
  return quality.isEmpty ? null : quality;
}

List<String> _distinctLabels(List<String> labels) {
  final seen = <String>{};
  final result = <String>[];
  for (final label in labels) {
    final cleaned = label.trim();
    if (cleaned.isEmpty) continue;
    if (seen.add(cleaned.toLowerCase())) result.add(cleaned);
  }
  return result;
}

String cleanLabel(String value) {
  final source = value.trim().replaceAll(RegExp(r'[-_]+'), ' ');
  if (source.isEmpty) return '';
  return source
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map(
        (w) => w.length == 1
            ? w.toUpperCase()
            : '${w[0].toUpperCase()}${w.substring(1)}',
      )
      .join(' ');
}
