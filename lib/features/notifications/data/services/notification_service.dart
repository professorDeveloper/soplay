import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/notifications/domain/repositories/notifications_repository.dart';

typedef NotificationTapHandler = void Function(Map<String, dynamic> data);

class NotificationService {
  final NotificationsRepository repository;
  NotificationTapHandler? onTap;

  bool _initialized = false;
  String? _registeredToken;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'soplay_default',
    'SoPlay bildirishnomalari',
    description: 'Asosiy bildirishnomalar kanali',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  NotificationService({required this.repository});

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (!Platform.isAndroid) {
      _initialized = true;
      return;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final payload = _decodePayload(resp.payload);
        if (payload != null) onTap?.call(payload);
      },
    );
    final androidImpl = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    _initialized = true;
  }

  Future<void> setup() async {
    if (!Platform.isAndroid) return;
    await ensureInitialized();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerToken,
    );

    _foregroundSub ??= FirebaseMessaging.onMessage.listen(_showLocal);

    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      onTap?.call(_normalizeData(msg.data));
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      onTap?.call(_normalizeData(initial.data));
    }
  }

  Future<void> unregister() async {
    if (!Platform.isAndroid) return;
    final token = _registeredToken ??
        await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await repository.unregisterFcmToken(token);
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _registeredToken = null;
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedSub = null;
    _tokenRefreshSub = null;
  }

  Future<void> _registerToken(String token) async {
    if (_registeredToken == token) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    final result = await repository.registerFcmToken(
      token: token,
      platform: platform,
    );
    if (result is Success) {
      _registeredToken = token;
    } else if (kDebugMode) {
      debugPrint('[FCM] register failed');
    }
  }

  Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;
    final data = _normalizeData(msg.data);
    await _local.show(
      n.hashCode,
      n.title ?? 'SoPlay',
      n.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: _encodePayload(data),
    );
  }

  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    return data.map((k, v) => MapEntry(k.toString(), v));
  }

  String? _encodePayload(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    final entries = data.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}')
        .join('&');
    return entries;
  }

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final out = <String, dynamic>{};
    for (final part in payload.split('&')) {
      final i = part.indexOf('=');
      if (i <= 0) continue;
      out[Uri.decodeComponent(part.substring(0, i))] =
          Uri.decodeComponent(part.substring(i + 1));
    }
    return out;
  }
}
