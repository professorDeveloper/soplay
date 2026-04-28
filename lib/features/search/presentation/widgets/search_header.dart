import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class SearchStickyHeader extends StatelessWidget {
  const SearchStickyHeader({
    super.key,
    required this.progress,
    required this.topPad,
    required this.controller,
    required this.focus,
    required this.hasActiveFilter,
    required this.onFilterTap,
    required this.onQueryChanged,
    required this.onClear,
  });

  final double progress;
  final double topPad;
  final TextEditingController controller;
  final FocusNode focus;
  final bool hasActiveFilter;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topPad + 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'search.title'.tr(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: controller,
                  focus: focus,
                  onChanged: onQueryChanged,
                  onClear: onClear,
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(active: hasActiveFilter, onTap: onFilterTap),
            ],
          ),
        ),
      ],
    );

    if (progress < 0.01) {
      return Container(color: AppColors.background, child: inner);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818).withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06 * progress),
              ),
            ),
          ),
          child: inner,
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focus,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1,
            ),
            decoration: InputDecoration(
              hintText: 'search.hint'.tr(),
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: widget.onClear,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.active});

  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
                if (active)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
