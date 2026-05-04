import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/detail/domain/entities/related_entity.dart';

class DetailRelatedSection extends StatelessWidget {
  const DetailRelatedSection({super.key, required this.related});
  final List<RelatedEntity> related;

  @override
  Widget build(BuildContext context) {
    if (related.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                color: AppColors.textHint,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'No recommendations available',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final items = related.length > 30 ? related.sublist(0, 30) : related;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 14,
          childAspectRatio: 0.66,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _RelatedCard(item: items[i]),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.item});
  final RelatedEntity item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.contentUrl.isNotEmpty) {
          context.push(
            '/detail',
            extra: DetailArgs(contentUrl: item.contentUrl),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _RelatedThumbnail(url: item.thumbnail),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title.trim().isNotEmpty ? item.title : 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if (item.year != null)
            Text(
              item.year.toString(),
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

class _RelatedThumbnail extends StatelessWidget {
  const _RelatedThumbnail({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppColors.textHint,
            size: 28,
          ),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppColors.textHint,
            size: 28,
          ),
        ),
      ),
      loadingBuilder: (_, child, chunk) =>
          chunk == null ? child : Container(color: AppColors.surfaceVariant),
    );
  }
}
