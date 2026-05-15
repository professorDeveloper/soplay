import 'package:flutter/foundation.dart';

class JsLog {
  static bool enabled = kDebugMode;

  static void req(String tag, String message) {
    if (!enabled) return;
    debugPrint('[$tag] → $message');
  }

  static void res(String tag, String message, {int? ms, int? status}) {
    if (!enabled) return;
    final parts = <String>[];
    if (status != null) parts.add('$status');
    if (ms != null) parts.add('${ms}ms');
    final suffix = parts.isEmpty ? '' : ' (${parts.join(' · ')})';
    debugPrint('[$tag] ← $message$suffix');
  }

  static void info(String tag, String message) {
    if (!enabled) return;
    debugPrint('[$tag] $message');
  }

  static void err(String tag, String message) {
    if (!enabled) return;
    debugPrint('[$tag] ✗ $message');
  }
}
