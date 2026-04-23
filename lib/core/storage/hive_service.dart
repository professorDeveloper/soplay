import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class HiveService {
  final Box _authBox = Hive.box(AppConstants.authBox);
  final Box _settingsBox = Hive.box(AppConstants.settingsBox);

  String? getToken() => _authBox.get(AppConstants.accessTokenKey);

  UserModel? getUser() {
    final raw = _authBox.get(AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
  }

  Future<void> saveAuth({required String token, required UserEntity user}) async {
    await _authBox.put(AppConstants.accessTokenKey, token);
    await _authBox.put(AppConstants.userKey, jsonEncode((user as UserModel).toJson()));
  }

  Future<void> clearAuth() async {
    await _authBox.delete(AppConstants.accessTokenKey);
    await _authBox.delete(AppConstants.userKey);
  }

  bool get isLoggedIn => getToken() != null;

  String getLanguage() {
    return _settingsBox.get(AppConstants.languageKey, defaultValue: 'en');
  }

  Future<void> saveLanguage(String langCode) async {
    await _settingsBox.put(AppConstants.languageKey, langCode);
  }
}
