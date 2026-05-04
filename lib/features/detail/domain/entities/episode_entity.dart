class EpisodeEntity {
  final int episode;
  final String label;
  final String mediaRef;
  final List<String> availableLangs;
  final bool? hasSub;
  final bool? hasDub;
  final String? image;
  final String? airdate;
  final String? runtime;
  final String? overview;

  const EpisodeEntity({
    required this.episode,
    required this.label,
    required this.mediaRef,
    this.availableLangs = const [],
    this.hasSub,
    this.hasDub,
    this.image,
    this.airdate,
    this.runtime,
    this.overview,
  });
}
