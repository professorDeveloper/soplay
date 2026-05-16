import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/app_updater/domain/entities/app_version_check.dart';
import 'package:soplay/features/app_updater/domain/repositories/app_updater_repository.dart';
import 'package:soplay/features/app_updater/presentation/pages/force_update_page.dart';
import 'package:soplay/features/app_updater/presentation/widgets/install_progress_dialog.dart';
import 'package:soplay/features/app_updater/presentation/widgets/update_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const _snoozeKey = 'app_update_snoozed_until';
  static const _snoozeDuration = Duration(hours: 24);

  final AppUpdaterRepository repository;
  bool _running = false;

  UpdateChecker({required this.repository});

  Future<void> run(BuildContext context) async {
    if (_running) return;
    _running = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final platform = Platform.isIOS ? 'ios' : 'android';
      final result = await repository.check(
        platform: platform,
        currentVersion: current,
      );
      if (result is! Success<AppVersionCheck>) return;
      final check = result.value;
      if (!check.updateAvailable) return;
      if (!context.mounted) return;

      if (check.forceUpdate) {
        if (!context.mounted) return;
        await _showForceUpdate(context, check);
        return;
      }
      if (_isSnoozed()) return;
      if (!context.mounted) return;
      final accepted = await showUpdateDialog(context, check);
      if (accepted == true) {
        if (!context.mounted) return;
        await _performUpdate(context, check);
      } else {
        await _snooze();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[UpdateChecker] $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _showForceUpdate(
    BuildContext context,
    AppVersionCheck check,
  ) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ForceUpdatePage(
          check: check,
          onUpdate: (ctx) => _performUpdate(ctx, check),
        ),
      ),
    );
  }

  Future<void> _performUpdate(
    BuildContext context,
    AppVersionCheck check,
  ) async {
    if (Platform.isAndroid) {
      if (check.downloadUrl != null) {
        await _downloadAndInstallApk(context, check.downloadUrl!);
      } else if (check.storeUrl != null) {
        await _openExternal(check.storeUrl!);
      }
      return;
    }
    if (check.storeUrl != null) {
      await _openExternal(check.storeUrl!);
    }
  }

  Future<void> _downloadAndInstallApk(
    BuildContext context,
    String url,
  ) async {
    final controller = InstallProgressController();
    showInstallProgressDialog(context, controller);
    try {
      final dir = await getTemporaryDirectory();
      final filename = 'soplay-${DateTime.now().millisecondsSinceEpoch}.apk';
      final path = '${dir.path}/$filename';
      final dio = Dio();
      await dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            controller.update(received / total);
          }
        },
      );
      controller.close();
      await OpenFilex.open(path, type: 'application/vnd.android.package-archive');
    } catch (e) {
      controller.fail(e.toString());
      if (kDebugMode) debugPrint('[UpdateChecker] APK download failed: $e');
    }
  }

  Future<void> _openExternal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  bool _isSnoozed() {
    final box = Hive.box(AppConstants.settingsBox);
    final ts = box.get(_snoozeKey);
    if (ts is! int) return false;
    return DateTime.now().millisecondsSinceEpoch < ts;
  }

  Future<void> _snooze() async {
    final box = Hive.box(AppConstants.settingsBox);
    final until = DateTime.now().add(_snoozeDuration).millisecondsSinceEpoch;
    await box.put(_snoozeKey, until);
  }
}
