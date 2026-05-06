import 'package:flutter/material.dart';
import 'package:soplay/core/storage/hive_service.dart';

class ThemeController extends ChangeNotifier {
  final HiveService _hive;

  ThemeController(this._hive) : _amoled = _hive.isAmoledMode;

  bool _amoled;
  bool get isAmoled => _amoled;

  Future<void> toggle() async {
    _amoled = !_amoled;
    await _hive.setAmoledMode(_amoled);
    notifyListeners();
  }
}
