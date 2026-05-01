import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/auth/domain/entities/user_entity.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_event.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';
import 'package:soplay/features/profile/domain/entities/provider_entity.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_bloc.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_event.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_state.dart';

final _tileIconDecoration = BoxDecoration(
  color: AppColors.textSecondary.withValues(alpha: 0.12),
  borderRadius: BorderRadius.circular(8),
);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProviderBloc>()..add(const ProviderLoad()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthStarted());
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPad + 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'profile.title'.tr(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthLoaded ? state.token.user : null;
                return _ProfileHeader(user: user);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: _ProfileOptionsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: _ConnectionsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: _ProvidersEntry()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: _AppInfoSection()),
          SliverToBoxAdapter(child: SizedBox(height: bottomPad + 96)),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    return _SectionContainer(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: currentUser == null
            ? _GuestContent(onLogin: () => context.push('/login'))
            : _UserContent(user: currentUser),
      ),
    );
  }
}

class _GuestContent extends StatelessWidget {
  const _GuestContent({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.textHint,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.guest_title'.tr(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'profile.guest_subtitle'.tr(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login_rounded, size: 19),
            label: Text('auth.sign_in'.tr()),
          ),
        ),
      ],
    );
  }
}

class _UserContent extends StatelessWidget {
  const _UserContent({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(user: user),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayIdentifier,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                user.email,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout_rounded),
          color: AppColors.textSecondary,
          tooltip: 'general.logout'.tr(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            fixedSize: const Size(42, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('general.logout'.tr()),
        content: Text('profile.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'general.logout'.tr(),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOptionsSection extends StatelessWidget {
  const _ProfileOptionsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(child: Column(children: [const _LanguageTile()]));
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  static const _languages = [
    (code: 'uz', label: "O'zbek"),
    (code: 'ru', label: 'Русский'),
    (code: 'en', label: 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          _TileIcon(icon: Icons.language_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'profile.language'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _languages.any((lang) => lang.code == currentCode)
                  ? currentCode
                  : 'en',
              dropdownColor: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              iconEnabledColor: AppColors.textSecondary,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem<String>(
                      value: lang.code,
                      child: Text(lang.label),
                    ),
                  )
                  .toList(),
              onChanged: (code) async {
                if (code == null || code == currentCode) return;
                await context.setLocale(Locale(code));
                await getIt<HiveService>().saveLanguage(code);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionsSection extends StatelessWidget {
  const _ConnectionsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            _TileIcon(icon: Icons.link_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'profile.connections'.tr(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'profile.coming_soon'.tr(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvidersEntry extends StatelessWidget {
  const _ProvidersEntry();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      label: 'profile.providers'.tr().toUpperCase(),
      child: BlocBuilder<ProviderBloc, ProviderState>(
        builder: (context, state) {
          final currentName = state is ProviderLoaded
              ? state.currentProvider?.name ?? state.currentProviderId
              : AppConstants.defaultProviderId;

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showProviders(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  const _TileIcon(icon: Icons.movie_filter_outlined),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.providers'.tr(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProviders(BuildContext context) {
    final providerBloc = context.read<ProviderBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: providerBloc,
        child: const _ProvidersSheet(),
      ),
    );
  }
}

class _ProvidersSheet extends StatelessWidget {
  const _ProvidersSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'profile.providers'.tr(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: BlocBuilder<ProviderBloc, ProviderState>(
              builder: (context, state) {
                return switch (state) {
                  ProviderLoaded() => _ProvidersList(state: state),
                  ProviderError() => _ProvidersError(
                    onRetry: () =>
                        context.read<ProviderBloc>().add(const ProviderLoad()),
                  ),
                  _ => const _ProvidersLoading(),
                };
              },
            ),
          ),
          SizedBox(height: bottomPad + 12),
        ],
      ),
    );
  }
}

class _ProvidersList extends StatelessWidget {
  const _ProvidersList({required this.state});

  final ProviderLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: state.providers.length,
      separatorBuilder: (context, index) =>
          const Divider(color: AppColors.divider, height: 1, indent: 66),
      itemBuilder: (context, index) {
        final provider = state.providers[index];
        final selected = provider.id == state.currentProviderId;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              context.read<ProviderBloc>().add(ProviderSelect(provider.id));
              Navigator.of(context).pop();
            },
            leading: _ProviderLogo(provider: provider),
            title: Text(
              provider.name,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: provider.url.isEmpty
                ? null
                : Text(
                    provider.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
            trailing: selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _ProvidersLoading extends StatelessWidget {
  const _ProvidersLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }
}

class _ProvidersError extends StatelessWidget {
  const _ProvidersError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(
            'profile.providers_error'.tr(),
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: Text('general.retry'.tr())),
        ],
      ),
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  const _AppInfoSection();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      label: 'profile.about'.tr().toUpperCase(),
      child: const _InfoTile(
        icon: Icons.info_outline_rounded,
        title: 'Soplay',
        value: '1.0.0',
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: _tileIconDecoration,
            child: Icon(icon, color: AppColors.textSecondary, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: _tileIconDecoration,
      child: Icon(icon, color: AppColors.textSecondary, size: 18),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                label!,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;
    final initials = _initials(user.displayIdentifier);

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl.isNotEmpty
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _Initials(initials: initials),
            )
          : _Initials(initials: initials),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? 'S' : name[0].toUpperCase();
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.provider});

  final ProviderEntity provider;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: provider.image.isEmpty
          ? _ProviderFallback(name: provider.name)
          : Image.network(
              provider.image,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _ProviderFallback(name: provider.name),
            ),
    );
  }
}

class _ProviderFallback extends StatelessWidget {
  const _ProviderFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
