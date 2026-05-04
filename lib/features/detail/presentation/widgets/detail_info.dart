import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/detail_entity.dart';
import 'package:soplay/features/home/domain/entities/view_all.dart';

class DetailContentHeader extends StatelessWidget {
  const DetailContentHeader({
    super.key,
    required this.detail,
    required this.onPrimaryAction,
    required this.playButtonKey,
  });

  final DetailEntity detail;
  final VoidCallback onPrimaryAction;
  final Key playButtonKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaLine(detail: detail),
          if (detail.genres.isNotEmpty) ...[
            const SizedBox(height: 10),
            _GenresRow(genres: detail.genres),
          ],
          if (detail.description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _ExpandableDescription(text: detail.description.trim()),
          ],
          const SizedBox(height: 18),
          _PlayButton(key: playButtonKey, onTap: onPrimaryAction),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.detail});
  final DetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (detail.year != null) detail.year.toString(),
      if (detail.duration != null && detail.duration!.trim().isNotEmpty)
        detail.duration!.trim(),
      if (detail.country != null && detail.country!.trim().isNotEmpty)
        detail.country!.trim(),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      widgets.add(
        Text(
          parts[i],
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      if (i != parts.length - 1) {
        widgets.add(const _Dot());
      }
    }
    return Row(children: widgets);
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(color: AppColors.textHint, fontSize: 12),
      ),
    );
  }
}

class _GenresRow extends StatelessWidget {
  const _GenresRow({required this.genres});
  final List<String> genres;

  static String _slugify(String value) {
    final s = value.trim().toLowerCase();
    return s
        .replaceAll(RegExp(r"\s+"), '-')
        .replaceAll(RegExp(r"-+"), '-');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: genres
            .take(8)
            .map(
              (g) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    final slug = _slugify(g);
                    if (slug.isEmpty) return;
                    context.push(
                      '/view-all',
                      extra: ViewAllEntity(type: 'genre', slug: slug),
                    );
                  },
                  child: _Chip(label: g),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});
  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 26),
        label: const Text(
          'Play',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
