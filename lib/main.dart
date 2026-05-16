import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/js/js_runtime_service.dart';
import 'package:soplay/core/js/provider_registry.dart';
import 'package:soplay/features/download/data/download_service.dart';
import 'package:soplay/features/notifications/data/services/notification_service.dart';

import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    _initHive(),
  ]);

  PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
  await _initFirebaseSafely();
  await configureDependencies();
  _fireAndForget(getIt<DownloadService>().resumeIncomplete(), 'download');
  _fireAndForget(getIt<ProviderRegistry>().preload(), 'providers');
  _fireAndForget(getIt<JsRuntimeService>().ensureReady(), 'js');
  _fireAndForget(
    getIt<NotificationService>().ensureInitialized(),
    'fcm',
  );
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((Object _) {}),
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('uz'),
        Locale('ru'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(AppConstants.authBox),
    Hive.openBox(AppConstants.settingsBox),
    Hive.openBox(AppConstants.historyBox),
    Hive.openBox(AppConstants.downloadBox),
    Hive.openBox(AppConstants.extractorsBox),
  ]);
}

void _fireAndForget(Future<void> future, String tag) {
  future.catchError((Object e) {
    if (kDebugMode) debugPrint('[$tag] background init failed: $e');
  });
}

Future<void> _initFirebaseSafely() async {
  if (!Platform.isAndroid) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    if (kDebugMode) debugPrint('[Firebase] init failed: $e');
  }
}
