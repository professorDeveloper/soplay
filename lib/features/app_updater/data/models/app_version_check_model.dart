import 'package:soplay/features/app_updater/domain/entities/app_version_check.dart';

class AppVersionCheckModel extends AppVersionCheck {
  const AppVersionCheckModel({
    required super.platform,
    required super.updateAvailable,
    required super.forceUpdate,
    required super.version,
    required super.minVersion,
    required super.downloadUrl,
    required super.storeUrl,
    required super.releaseNotes,
  });

  factory AppVersionCheckModel.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(dynamic raw) {
      if (raw is! String) return null;
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }

    int asInt(dynamic raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    return AppVersionCheckModel(
      platform: json['platform'] as String? ?? '',
      updateAvailable: json['updateAvailable'] as bool? ?? false,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      version: asInt(json['version']),
      minVersion: asInt(json['minVersion']),
      downloadUrl: nonEmpty(json['downloadUrl']),
      storeUrl: nonEmpty(json['storeUrl']),
      releaseNotes: nonEmpty(json['releaseNotes']),
    );
  }
}
