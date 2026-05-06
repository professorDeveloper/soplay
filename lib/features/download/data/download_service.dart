import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/features/download/domain/entities/download_item.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class DownloadService {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _tokens = {};
  int _activeCount = 0;

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Box get _box => Hive.box(AppConstants.downloadBox);

  List<DownloadItem> getAll() {
    final items = <DownloadItem>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is String) {
          items.add(DownloadItem.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ));
        }
      } catch (_) {}
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  DownloadItem? get(String id) {
    final raw = _box.get(id);
    if (raw is! String) return null;
    try {
      return DownloadItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  bool isDownloaded(String id) {
    final item = get(id);
    return item != null && item.status == DownloadStatus.completed;
  }

  int _lastRevisionMs = 0;

  Future<void> _save(DownloadItem item, {bool force = false}) async {
    await _box.put(item.id, jsonEncode(item.toJson()));
    final now = DateTime.now().millisecondsSinceEpoch;
    if (force || now - _lastRevisionMs > 500) {
      _lastRevisionMs = now;
      revision.value++;
    }
  }

  Future<void> _acquireWakelock() async {
    _activeCount++;
    if (_activeCount == 1) await WakelockPlus.enable();
  }

  Future<void> _releaseWakelock() async {
    _activeCount--;
    if (_activeCount <= 0) {
      _activeCount = 0;
      await WakelockPlus.disable();
    }
  }

  Future<String> _itemDir(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final dlDir = Directory('${dir.path}/downloads/$id');
    if (!await dlDir.exists()) await dlDir.create(recursive: true);
    return dlDir.path;
  }

  bool _isHls(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8');
  }

  Future<void> startDownload(DownloadItem item) async {
    if (_tokens.containsKey(item.id)) return;

    final cancel = CancelToken();
    _tokens[item.id] = cancel;

    var dl = item.copyWith(status: DownloadStatus.downloading);
    await _save(dl, force: true);
    await _acquireWakelock();

    try {
      if (_isHls(item.videoUrl)) {
        dl = await _downloadHls(dl, cancel);
      } else {
        dl = await _downloadDirect(dl, cancel);
      }
      dl = dl.copyWith(status: DownloadStatus.completed);
      await _save(dl, force: true);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      dl = dl.copyWith(status: DownloadStatus.failed);
      await _save(dl, force: true);
    } catch (e) {
      debugPrint('[DOWNLOAD] error: $e');
      dl = dl.copyWith(status: DownloadStatus.failed);
      await _save(dl, force: true);
    } finally {
      _tokens.remove(item.id);
      await _releaseWakelock();
    }
  }

  Future<void> resumeIncomplete() async {
    final items = getAll();
    for (final item in items) {
      if (item.status == DownloadStatus.downloading) {
        startDownload(item);
      }
    }
  }

  Future<DownloadItem> _downloadDirect(
    DownloadItem dl,
    CancelToken cancel,
  ) async {
    final dir = await _itemDir(dl.id);
    final ext = _extensionFrom(dl.videoUrl);
    final path = '$dir/video$ext';

    var current = dl.copyWith(localPath: path);
    await _save(current);

    await _dio.download(
      dl.videoUrl,
      path,
      cancelToken: cancel,
      options: Options(headers: dl.headers),
      onReceiveProgress: (received, total) {
        current = current.copyWith(
          downloadedBytes: received,
          totalBytes: total > 0 ? total : 0,
        );
        _save(current);
      },
    );
    return current;
  }

  Future<DownloadItem> _downloadHls(
    DownloadItem dl,
    CancelToken cancel,
  ) async {
    final dir = await _itemDir(dl.id);

    final m3u8Resp = await _dio.get<String>(
      dl.videoUrl,
      cancelToken: cancel,
      options: Options(
        headers: dl.headers,
        responseType: ResponseType.plain,
      ),
    );
    final m3u8 = m3u8Resp.data ?? '';
    final baseUrl = _baseUrlOf(dl.videoUrl);

    String mediaPlaylist = m3u8;
    String mediaBaseUrl = baseUrl;

    if (_isMasterPlaylist(m3u8)) {
      final variantUrl = _pickVariantUrl(m3u8, baseUrl);
      if (variantUrl == null) throw Exception('No variant found in m3u8');
      final varResp = await _dio.get<String>(
        variantUrl,
        cancelToken: cancel,
        options: Options(
          headers: dl.headers,
          responseType: ResponseType.plain,
        ),
      );
      mediaPlaylist = varResp.data ?? '';
      mediaBaseUrl = _baseUrlOf(variantUrl);
    }

    final segments = _parseSegments(mediaPlaylist, mediaBaseUrl);
    if (segments.isEmpty) throw Exception('No segments in m3u8');

    final totalSegments = segments.length;
    var downloaded = 0;
    var totalBytes = 0;

    var current = dl.copyWith(
      localPath: '$dir/index.m3u8',
      totalBytes: totalSegments,
      downloadedBytes: 0,
    );
    await _save(current, force: true);

    for (var i = 0; i < segments.length; i++) {
      if (cancel.isCancelled) return current;
      final segFile = '$dir/seg_$i.ts';
      final file = File(segFile);
      if (await file.exists() && await file.length() > 0) {
        totalBytes += await file.length();
        downloaded++;
        continue;
      }
      await _dio.download(
        segments[i],
        segFile,
        cancelToken: cancel,
        options: Options(headers: dl.headers),
      );
      final size = await File(segFile).length();
      totalBytes += size;
      downloaded++;
      current = current.copyWith(
        downloadedBytes: downloaded,
        totalBytes: totalSegments,
      );
      _save(current);
    }

    final localM3u8 = _buildLocalM3u8(mediaPlaylist);
    await File('$dir/index.m3u8').writeAsString(localM3u8);

    return current.copyWith(totalBytes: totalBytes);
  }

  bool _isMasterPlaylist(String m3u8) {
    return m3u8.contains('#EXT-X-STREAM-INF');
  }

  String? _pickVariantUrl(String m3u8, String baseUrl) {
    final lines = m3u8.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
        for (var j = i + 1; j < lines.length; j++) {
          final line = lines[j].trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          return _resolveUrl(line, baseUrl);
        }
      }
    }
    return null;
  }

  List<String> _parseSegments(String m3u8, String baseUrl) {
    final segments = <String>[];
    for (final line in m3u8.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      segments.add(_resolveUrl(trimmed, baseUrl));
    }
    return segments;
  }

  String _buildLocalM3u8(String original) {
    final buf = StringBuffer();
    var segIdx = 0;
    for (final line in original.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        buf.writeln(trimmed);
      } else {
        buf.writeln('seg_$segIdx.ts');
        segIdx++;
      }
    }
    return buf.toString();
  }

  String _baseUrlOf(String url) {
    final lastSlash = url.lastIndexOf('/');
    return lastSlash > 0 ? url.substring(0, lastSlash + 1) : url;
  }

  String _resolveUrl(String path, String baseUrl) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}$path';
    }
    return '$baseUrl$path';
  }

  void cancelDownload(String id) {
    _tokens[id]?.cancel();
    _tokens.remove(id);
  }

  Future<void> remove(String id) async {
    cancelDownload(id);
    final dir = await _itemDir(id);
    final folder = Directory(dir);
    if (await folder.exists()) await folder.delete(recursive: true);
    await _box.delete(id);
    revision.value++;
  }

  Future<void> clearAll() async {
    _tokens.forEach((_, t) => t.cancel());
    _tokens.clear();
    final base = await getApplicationDocumentsDirectory();
    final dlDir = Directory('${base.path}/downloads');
    if (await dlDir.exists()) await dlDir.delete(recursive: true);
    await _box.clear();
    revision.value++;
  }

  String _extensionFrom(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '.mp4';
    final path = uri.path.toLowerCase();
    if (path.endsWith('.mp4')) return '.mp4';
    if (path.endsWith('.mkv')) return '.mkv';
    if (path.endsWith('.ts')) return '.ts';
    return '.mp4';
  }
}
