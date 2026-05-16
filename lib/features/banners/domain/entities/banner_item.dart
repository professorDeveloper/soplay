class BannerItem {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? link;
  final String placement;
  final int order;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.link,
    required this.placement,
    required this.order,
  });
}

class BannerPlacement {
  BannerPlacement._();
  static const String homeTop = 'home_top';
  static const String homeMiddle = 'home_middle';
  static const String shortsTop = 'shorts_top';
  static const String detailTop = 'detail_top';
  static const String other = 'other';
}
