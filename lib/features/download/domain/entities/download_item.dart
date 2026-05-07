enum DownloadStatus { pending, downloading, completed, failed }

class DownloadItem {
  final String id;
  final String contentUrl;
  final String provider;
  final String title;
  final String? thumbnail;
  final String? localThumbnailPath;
  final String videoUrl;
  final String localPath;
  final Map<String, String> headers;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final int createdAt;
  final bool isSerial;
  final int? episodeNumber;
  final String? episodeLabel;

  const DownloadItem({
    required this.id,
    required this.contentUrl,
    required this.provider,
    required this.title,
    required this.videoUrl,
    required this.localPath,
    this.thumbnail,
    this.localThumbnailPath,
    this.headers = const {},
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    required this.createdAt,
    this.isSerial = false,
    this.episodeNumber,
    this.episodeLabel,
  });

  double get progress =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  String? get displayThumbnail {
    final local = localThumbnailPath?.trim();
    if (local != null && local.isNotEmpty) return local;
    return thumbnail;
  }

  DownloadItem copyWith({
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    String? localPath,
    String? localThumbnailPath,
  }) => DownloadItem(
    id: id,
    contentUrl: contentUrl,
    provider: provider,
    title: title,
    thumbnail: thumbnail,
    localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
    videoUrl: videoUrl,
    localPath: localPath ?? this.localPath,
    headers: headers,
    totalBytes: totalBytes ?? this.totalBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    status: status ?? this.status,
    createdAt: createdAt,
    isSerial: isSerial,
    episodeNumber: episodeNumber,
    episodeLabel: episodeLabel,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contentUrl': contentUrl,
    'provider': provider,
    'title': title,
    'thumbnail': thumbnail,
    'localThumbnailPath': localThumbnailPath,
    'videoUrl': videoUrl,
    'localPath': localPath,
    'headers': headers,
    'totalBytes': totalBytes,
    'downloadedBytes': downloadedBytes,
    'status': status.index,
    'createdAt': createdAt,
    'isSerial': isSerial,
    'episodeNumber': episodeNumber,
    'episodeLabel': episodeLabel,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    id: json['id'] as String? ?? '',
    contentUrl: json['contentUrl'] as String? ?? '',
    provider: json['provider'] as String? ?? '',
    title: json['title'] as String? ?? '',
    thumbnail: json['thumbnail'] as String?,
    localThumbnailPath: json['localThumbnailPath'] as String?,
    videoUrl: json['videoUrl'] as String? ?? '',
    localPath: json['localPath'] as String? ?? '',
    headers:
        (json['headers'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const {},
    totalBytes: json['totalBytes'] as int? ?? 0,
    downloadedBytes: json['downloadedBytes'] as int? ?? 0,
    status: DownloadStatus.values[(json['status'] as int? ?? 0).clamp(0, 3)],
    createdAt: json['createdAt'] as int? ?? 0,
    isSerial: json['isSerial'] as bool? ?? false,
    episodeNumber: json['episodeNumber'] as int?,
    episodeLabel: json['episodeLabel'] as String?,
  );
}
