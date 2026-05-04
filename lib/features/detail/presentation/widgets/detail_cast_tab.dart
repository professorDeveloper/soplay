import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/cast_entity.dart';
import 'package:soplay/features/detail/presentation/pages/actor_page.dart';

class DetailCastTab extends StatelessWidget {
  const DetailCastTab({super.key, required this.cast, this.director});

  final List<CastEntity> cast;
  final String? director;

  @override
  Widget build(BuildContext context) {
    final hasDirector = director != null && director!.trim().isNotEmpty;

    if (cast.isEmpty && !hasDirector) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: AppColors.textHint,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'No cast available',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDirector)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _DirectorTile(director: director!.trim()),
            ),
          if (hasDirector && cast.isNotEmpty) const SizedBox(height: 16),
          if (cast.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cast.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (_, i) => _CastGridCard(cast: cast[i]),
            ),
        ],
      ),
    );
  }
}

class _DirectorTile extends StatelessWidget {
  const _DirectorTile({required this.director});
  final String director;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.movie_creation_outlined,
            color: AppColors.textHint,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Text(
            'Director',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              director,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CastGridCard extends StatelessWidget {
  const _CastGridCard({required this.cast});
  final CastEntity cast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (cast.name.trim().isEmpty) return;
        context.push(
          '/actor',
          extra: ActorArgs(name: cast.name.trim(), image: cast.image),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CastAvatar(name: cast.name, imageUrl: cast.image),
            const SizedBox(height: 8),
            Text(
              cast.name.trim().isNotEmpty ? cast.name : '—',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Actor',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
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

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final t = name.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(initials: _initials),
              loadingBuilder: (_, child, chunk) =>
                  chunk == null ? child : _Initials(initials: _initials),
            )
          : _Initials(initials: _initials),
    );
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
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
