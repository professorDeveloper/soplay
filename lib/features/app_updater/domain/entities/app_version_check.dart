class AppVersionCheck {
  final String platform;
  final bool updateAvailable;
  final bool forceUpdate;
  final int version;
  final int minVersion;
  final String? downloadUrl;
  final String? storeUrl;
  final String? releaseNotes;

  const AppVersionCheck({
    required this.platform,
    required this.updateAvailable,
    required this.forceUpdate,
    required this.version,
    required this.minVersion,
    required this.downloadUrl,
    required this.storeUrl,
    required this.releaseNotes,
  });
}
