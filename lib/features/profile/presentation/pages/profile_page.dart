import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_bloc.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_event.dart';
import 'package:soplay/features/profile/presentation/widgets/profile_connections_section.dart';
import 'package:soplay/features/profile/presentation/widgets/profile_providers_section.dart';
import 'package:soplay/features/profile/presentation/widgets/profile_section_card.dart';
import 'package:soplay/features/profile/presentation/widgets/profile_support_section.dart';
import 'package:soplay/features/profile/presentation/widgets/profile_user_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProviderBloc>()..add(const ProviderLoad()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) context.go('/login');
        },
        child: const _ProfileView(),
      ),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final ScrollController _scrollController;
  final _blurProgress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    final next = _scrollController.hasClients
        ? (_scrollController.offset / 60).clamp(0.0, 1.0)
        : 0.0;
    if ((next - _blurProgress.value).abs() < 0.02) return;
    _blurProgress.value = next;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _blurProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPad)),
              const SliverToBoxAdapter(child: ProfileUserHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: ProfileProvidersSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: _DevelopersSection()),
              SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode.toUpperCase();

    return ProfileSectionCard(
      label: 'SETTINGS',
      child: Column(
        children: [
          ProfileListTile(
            icon: Icons.language_rounded,
            title: 'Language',
            trailing: languageCode,
            onTap: () => context.push('/settings/language'),
          ),
          ProfileListTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Player',
            onTap: () => context.push('/settings/player'),
          ),
          ProfileListTile(
            icon: Icons.manage_accounts_rounded,
            title: 'Account',
            showDivider: false,
            onTap: () => context.push('/settings/account'),
          ),
        ],
      ),
    );
  }
}

class _DevelopersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      label: 'DEVELOPERS',
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soplay',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1, indent: 16),
          ProfileListTile(
            icon: Icons.code_rounded,
            title: 'Open Source',
            showDivider: false,
            showChevron: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
