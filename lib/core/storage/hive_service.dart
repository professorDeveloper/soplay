import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/models/user_model.dart';

class HiveService {
  final Box _authBox = Hive.box(AppConstants.authBox);
  final Box _settingsBox = Hive.box(AppConstants.settingsBox);

  String? getToken() => _authBox.get(AppConstants.accessTokenKey);
  String? getRefreshToken() => _authBox.get(AppConstants.refreshTokenKey);

  UserModel? getUser() {
    final raw = _authBox.get(AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(
      jsonDecode(raw as String) as Map<String, dynamic>,
    );
  }

  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _authBox.put(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _authBox.put(AppConstants.accessTokenKey, accessToken);
    await _authBox.put(AppConstants.refreshTokenKey, refreshToken);
  }

  Future<void> saveUser(UserModel user) async {
    await _authBox.put(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearAuth() async {
    await _authBox.delete(AppConstants.accessTokenKey);
    await _authBox.delete(AppConstants.refreshTokenKey);
    await _authBox.delete(AppConstants.userKey);
  }

  bool get isLoggedIn => getToken()?.isNotEmpty == true;

  String? getAniListToken() => _authBox.get(AppConstants.aniListTokenKey);
  bool get isAniListConnected => getAniListToken() != null;

  Future<void> saveAniListToken(String token) async =>
      _authBox.put(AppConstants.aniListTokenKey, token);

  Future<void> clearAniListToken() async =>
      _authBox.delete(AppConstants.aniListTokenKey);

  String? getMalToken() => _authBox.get(AppConstants.malTokenKey);
  bool get isMalConnected => getMalToken() != null;

  Future<void> saveMalToken(String token) async =>
      _authBox.put(AppConstants.malTokenKey, token);

  Future<void> clearMalToken() async =>
      _authBox.delete(AppConstants.malTokenKey);

  String getCurrentProvider() {
    return _settingsBox.get(AppConstants.currentProviderKey, defaultValue: '');
  }

  Future<void> saveCurrentProvider(String providerId) async {
    await _settingsBox.put(AppConstants.currentProviderKey, providerId);
  }

  bool get hasSeenShortsRefreshShowcase {
    return _settingsBox.get(
          AppConstants.shortsRefreshShowcaseSeenKey,
          defaultValue: false,
        ) ==
        true;
  }

  Future<void> markShortsRefreshShowcaseSeen() async {
    await _settingsBox.put(AppConstants.shortsRefreshShowcaseSeenKey, true);
  }

  String getLanguage() {
    return _settingsBox.get(AppConstants.languageKey, defaultValue: 'en');
  }

  Future<void> saveLanguage(String langCode) async {
    await _settingsBox.put(AppConstants.languageKey, langCode);
  }

  String getPreferredMediaLang() {
    return _settingsBox.get(
      AppConstants.preferredMediaLangKey,
      defaultValue: AppConstants.defaultMediaLang,
    );
  }

  Future<void> savePreferredMediaLang(String lang) async {
    await _settingsBox.put(AppConstants.preferredMediaLangKey, lang);
  }
}
