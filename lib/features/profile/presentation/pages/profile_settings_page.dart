import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/profile/presentation/widgets/profile_section_card.dart';


class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  static const _languages = [
    (code: 'uz', label: "O'zbek", flag: '🇺🇿'),
    (code: 'ru', label: 'Русский', flag: '🇷🇺'),
    (code: 'en', label: 'English', flag: '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackHeader(title: 'Language'),
            const SizedBox(height: 16),
            ProfileSectionCard(
              label: 'SELECT LANGUAGE',
              child: Column(
                children: List.generate(
                  _languages.length,
                  (i) {
                    final lang = _languages[i];
                    final selected = lang.code == currentCode;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            await context.setLocale(Locale(lang.code));
                            await getIt<HiveService>()
                                .saveLanguage(lang.code);
                            if (context.mounted) context.pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  lang.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    lang.label,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (i < _languages.length - 1)
                          const Divider(
                            color: AppColors.divider,
                            height: 1,
                            indent: 54,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Player Settings Page ───────────────────────────────────────────────────

class PlayerSettingsPage extends StatefulWidget {
  const PlayerSettingsPage({super.key});

  @override
  State<PlayerSettingsPage> createState() => _PlayerSettingsPageState();
}

class _PlayerSettingsPageState extends State<PlayerSettingsPage> {
  bool _autoPlay = true;
  bool _autoSkipIntro = false;
  bool _autoNextEpisode = true;
  bool _subtitles = true;
  String _quality = 'Auto';

  static const _qualities = ['Auto', '1080p', '720p', '480p', '360p'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackHeader(title: 'Player'),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileSectionCard(
                      label: 'PLAYBACK',
                      child: Column(
                        children: [
                          _ToggleTile(
                            icon: Icons.play_arrow_rounded,
                            title: 'Auto Play',
                            subtitle: 'Start playing automatically',
                            value: _autoPlay,
                            onChanged: (v) => setState(() => _autoPlay = v),
                          ),
                          const Divider(
                            color: AppColors.divider,
                            height: 1,
                            indent: 62,
                          ),
                          _ToggleTile(
                            icon: Icons.skip_next_rounded,
                            title: 'Skip Intro',
                            subtitle: 'Automatically skip opening sequences',
                            value: _autoSkipIntro,
                            onChanged: (v) =>
                                setState(() => _autoSkipIntro = v),
                          ),
                          const Divider(
                            color: AppColors.divider,
                            height: 1,
                            indent: 62,
                          ),
                          _ToggleTile(
                            icon: Icons.fast_forward_rounded,
                            title: 'Auto Next Episode',
                            subtitle: 'Play next episode automatically',
                            value: _autoNextEpisode,
                            onChanged: (v) =>
                                setState(() => _autoNextEpisode = v),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProfileSectionCard(
                      label: 'DISPLAY',
                      child: Column(
                        children: [
                          _ToggleTile(
                            icon: Icons.subtitles_outlined,
                            title: 'Subtitles',
                            subtitle: 'Show subtitles when available',
                            value: _subtitles,
                            onChanged: (v) => setState(() => _subtitles = v),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProfileSectionCard(
                      label: 'QUALITY',
                      child: Column(
                        children: List.generate(
                          _qualities.length,
                          (i) {
                            final q = _qualities[i];
                            final selected = q == _quality;
                            return Column(
                              children: [
                                InkWell(
                                  onTap: () => setState(() => _quality = q),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            q,
                                            style: TextStyle(
                                              color: selected
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                              fontSize: 15,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        if (selected)
                                          const Icon(
                                            Icons.check_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (i < _qualities.length - 1)
                                  const Divider(
                                    color: AppColors.divider,
                                    height: 1,
                                    indent: 16,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account Settings Page ──────────────────────────────────────────────────

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _notifications = true;
  bool _emailUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackHeader(title: 'Account'),
            const SizedBox(height: 16),
            ProfileSectionCard(
              label: 'NOTIFICATIONS',
              child: Column(
                children: [
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'New releases and updates',
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const Divider(
                    color: AppColors.divider,
                    height: 1,
                    indent: 62,
                  ),
                  _ToggleTile(
                    icon: Icons.email_outlined,
                    title: 'Email Updates',
                    subtitle: 'Receive updates via email',
                    value: _emailUpdates,
                    onChanged: (v) => setState(() => _emailUpdates = v),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ProfileSectionCard(
              label: 'DANGER ZONE',
              child: ProfileListTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Account',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                showDivider: false,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              CupertinoIcons.chevron_back,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),


        if (showDivider)
          const Divider(color: AppColors.divider, height: 1, indent: 62),
      ],
    );
  }
}
