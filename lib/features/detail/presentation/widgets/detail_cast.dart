import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/cast_entity.dart';
import 'package:soplay/features/detail/presentation/pages/actor_page.dart';

class DetailCastSection extends StatelessWidget {
  const DetailCastSection({super.key, required this.cast, this.director});

  final List<CastEntity> cast;
  final String? director;

  @override
  Widget build(BuildContext context) {
    final hasCast = cast.isNotEmpty;
    final hasDirector = director != null && director!.trim().isNotEmpty;
    if (!hasCast && !hasDirector) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDirector)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, hasCast ? 8 : 0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                  children: [
                    const TextSpan(text: 'Director: '),
                    TextSpan(
                      text: director!.trim(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasCast) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Text(
                'Cast',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              height: 104,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: cast.length,
                itemBuilder: (_, i) => _CastCard(cast: cast[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  const _CastCard({required this.cast});

  final CastEntity cast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (cast.name.trim().isEmpty) return;
        context.push(
          '/actor',
          extra: ActorArgs(
            name: cast.name.trim(),
            image: cast.image,
            id: cast.id!,
          ),
        );
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CastAvatar(name: cast.name, imageUrl: cast.image),
            const SizedBox(height: 7),
            Text(
              cast.name.trim().isNotEmpty ? cast.name : '—',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastAvatar extends StatelessWidget {
  const _CastAvatar({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(initials: initials),
              loadingBuilder: (_, child, chunk) =>
                  chunk == null ? child : _Initials(initials: initials),
            )
          : _Initials(initials: initials),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
