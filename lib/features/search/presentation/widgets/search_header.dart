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
    final compactProgress = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0),
    );
    final topSpacing = lerpDouble(topPad + 18, topPad + 10, compactProgress)!;
    final titleHeight = lerpDouble(28, 0, compactProgress)!;
    final titleGap = lerpDouble(14, 8, compactProgress)!;
    final bottomGap = lerpDouble(16, 10, compactProgress)!;
    final backgroundColor = progress < 0.01
        ? AppColors.background
        : const Color(0xFF181818).withValues(alpha: 0.82);

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topSpacing),
        ClipRect(
          child: SizedBox(
            height: titleHeight,
            child: Opacity(
              opacity: 1 - compactProgress,
              child: Transform.translate(
                offset: Offset(0, -10 * compactProgress),
                child: Padding(
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
              ),
            ),
          ),
        ),
        SizedBox(height: titleGap),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomGap),
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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20 * progress, sigmaY: 20 * progress),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
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
    widget.focus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    widget.focus.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focus.hasFocus;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 46,
          decoration: BoxDecoration(
            color: focused
                ? AppColors.surfaceVariant.withValues(alpha: 0.96)
                : AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused
                  ? AppColors.primary.withValues(alpha: 0.58)
                  : Colors.white.withValues(alpha: 0.08),
              width: focused ? 1.2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focus,
            cursorRadius: const Radius.circular(14),
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1,
            ),
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
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
            onTapOutside: (_) => widget.focus.unfocus(),
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
