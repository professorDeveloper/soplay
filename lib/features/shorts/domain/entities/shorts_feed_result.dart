import 'short_entity.dart';

class ShortsFeedResult {
  const ShortsFeedResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ShortEntity> items;
  final String? nextCursor;
  final bool hasMore;
}
