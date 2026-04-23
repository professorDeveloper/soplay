import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:soplay/core/constants/app_constants.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.settingsBox);
  runApp(const MyApp());
}