import 'package:soplay/features/home/domain/entities/content_filter_entity.dart';

class ContentFilterModel extends ContentFilterEntity {
  const ContentFilterModel({
    required super.provider,
    required super.slug,
    required super.path,
    required super.url,
  });

  factory ContentFilterModel.fromJson(Map<String, dynamic> json) {
    return ContentFilterModel(
      provider: json['provider'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      path: json['path'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
