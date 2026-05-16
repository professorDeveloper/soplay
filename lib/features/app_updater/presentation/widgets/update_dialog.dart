import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/app_updater/domain/entities/app_version_check.dart';

const Color _androidAccent = Color(0xFF10B981);
const Color _iosAccent = Color(0xFF0F172A);

Future<bool?> showUpdateDialog(
  BuildContext context,
  AppVersionCheck check,
) {
  if (Platform.isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CupertinoUpdateDialog(check: check),
    );
  }
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _MaterialUpdateDialog(check: check),
  );
}

class _MaterialUpdateDialog extends StatelessWidget {
  const _MaterialUpdateDialog({required this.check});
  final AppVersionCheck check;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Yangi versiya bor (v${check.version})',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          check.releaseNotes ?? 'Ilovaning yangi versiyasi mavjud.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Keyinroq',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _androidAccent),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yangilash'),
        ),
      ],
    );
  }
}

class _CupertinoUpdateDialog extends StatelessWidget {
  const _CupertinoUpdateDialog({required this.check});
  final AppVersionCheck check;

  @override
  Widget build(BuildContext context) {
    final hasStore = check.storeUrl != null && check.storeUrl!.isNotEmpty;
    return CupertinoAlertDialog(
      title: Text('Yangi versiya bor (v${check.version})'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(check.releaseNotes ?? 'Ilovaning yangi versiyasi mavjud.'),
      ),
      actions: [
        if (hasStore)
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keyinroq'),
          ),
        if (hasStore)
          CupertinoDialogAction(
            isDefaultAction: true,
            textStyle: const TextStyle(color: _iosAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('App Store\'da ochish'),
          )
        else
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('OK'),
          ),
      ],
    );
  }
}
