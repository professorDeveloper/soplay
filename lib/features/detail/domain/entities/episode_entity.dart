class EpisodeEntity {
  final int episode;
  final String label;
  final String mediaRef;
  final List<String> availableLangs;
  final bool? hasSub;
  final bool? hasDub;

  const EpisodeEntity({
    required this.episode,
    required this.label,
    required this.mediaRef,
    this.availableLangs = const [],
    this.hasSub,
    this.hasDub,
  });
}
