import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/js/js_runtime_service.dart';
import 'package:soplay/features/download/data/download_service.dart';

import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    _initHive(),
  ]);

  await configureDependencies();
  unawaited(getIt<DownloadService>().resumeIncomplete());
  unawaited(getIt<JsRuntimeService>().ensureReady());
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
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

void unawaited(Future<void> future) {}
