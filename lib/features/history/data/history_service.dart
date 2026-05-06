import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/features/history/domain/entities/history_item.dart';

class HistoryService {
  static const int _maxItems = 50;

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Box get _box => Hive.box(AppConstants.historyBox);

  List<HistoryItem> getAll() {
    final items = <HistoryItem>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is String) {
          items.add(HistoryItem.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ));
        }
      } catch (_) {}
    }
    items.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return items;
  }

  HistoryItem? get(String contentUrl) {
    final raw = _box.get(contentUrl);
    if (raw is! String) return null;
    try {
      return HistoryItem.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(HistoryItem item) async {
    await _box.put(item.contentUrl, jsonEncode(item.toJson()));
    await _trimIfNeeded();
    revision.value++;
  }

  Future<void> remove(String contentUrl) async {
    await _box.delete(contentUrl);
    revision.value++;
  }

  Future<void> clearAll() async {
    await _box.clear();
    revision.value++;
  }

  Future<void> _trimIfNeeded() async {
    if (_box.length <= _maxItems) return;
    final items = getAll();
    if (items.length <= _maxItems) return;
    final toRemove = items.sublist(_maxItems);
    for (final item in toRemove) {
      await _box.delete(item.contentUrl);
    }
  }
}
