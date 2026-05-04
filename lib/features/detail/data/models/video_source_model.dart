import 'package:soplay/features/detail/domain/entities/video_source_entity.dart';

class VideoSourceModel extends VideoSourceEntity {
  const VideoSourceModel({
    required super.quality,
    required super.videoUrl,
    required super.isDefault,
    required super.accessible,
  });

  factory VideoSourceModel.fromJson(Map<String, dynamic> json) =>
      VideoSourceModel(
        quality: json['quality'] as String? ?? '',
        videoUrl: json['videoUrl'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
        accessible: json['accessible'] as bool? ?? false,
      );
}
