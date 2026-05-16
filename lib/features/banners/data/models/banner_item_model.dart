import 'package:soplay/features/banners/domain/entities/banner_item.dart';

class BannerItemModel extends BannerItem {
  const BannerItemModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.imageUrl,
    required super.link,
    required super.placement,
    required super.order,
  });

  factory BannerItemModel.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(dynamic raw) {
      if (raw is! String) return null;
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }

    return BannerItemModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: nonEmpty(json['subtitle']),
      imageUrl: json['imageUrl'] as String? ?? '',
      link: nonEmpty(json['link']),
      placement: json['placement'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
