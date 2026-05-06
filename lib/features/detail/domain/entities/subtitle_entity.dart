class SubtitleEntity {
  final String label;
  final String file;
  final bool isDefault;

  const SubtitleEntity({
    required this.label,
    required this.file,
    this.isDefault = false,
  });
}
