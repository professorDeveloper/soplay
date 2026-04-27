import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'search.title'.tr(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'search.hint'.tr(),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                          onPressed: () => setState(_controller.clear),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'search.categories'.tr(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) =>
                      _CategoryChip(data: _categories[i]),
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

const _categories = [
  _Cat('home.action', Icons.local_fire_department_rounded, Color(0xFF8B1A1A)),
  _Cat('home.comedy', Icons.sentiment_very_satisfied_rounded, Color(0xFF1A5C8B)),
  _Cat('home.drama', Icons.theater_comedy_rounded, Color(0xFF5C1A8B)),
  _Cat('home.thriller', Icons.remove_red_eye_rounded, Color(0xFF1A3A5C)),
  _Cat('home.horror', Icons.dark_mode_rounded, Color(0xFF2A0A2A)),
  _Cat('home.romance', Icons.favorite_rounded, Color(0xFF8B1A4A)),
  _Cat('home.sci_fi', Icons.rocket_launch_rounded, Color(0xFF0A3A5C)),
  _Cat('home.animation', Icons.animation_rounded, Color(0xFF1A6B1A)),
  _Cat('home.documentary', Icons.videocam_rounded, Color(0xFF5C4A1A)),
];

class _Cat {
  const _Cat(this.key, this.icon, this.color);
  final String key;
  final IconData icon;
  final Color color;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.data});
  final _Cat data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(data.icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.key.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
