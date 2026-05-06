import 'package:soplay/features/detail/domain/entities/subtitle_entity.dart';

class SubtitleModel extends SubtitleEntity {
  const SubtitleModel({
    required super.label,
    required super.file,
    required super.isDefault,
  });

  factory SubtitleModel.fromJson(Map<String, dynamic> json) => SubtitleModel(
        label: json['label'] as String? ?? '',
        file: json['file'] as String? ?? '',
        isDefault: json['default'] as bool? ?? false,
      );
}
