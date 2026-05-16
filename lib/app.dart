import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_event.dart';
import 'package:soplay/features/detail/domain/entities/detail_args.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_bloc.dart';
import 'package:soplay/features/notifications/data/services/notification_service.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_bloc.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_event.dart';
import 'package:soplay/features/search/presentation/blocs/search_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home/home_bloc.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    getIt<NotificationService>().onTap = _handlePushTap;
  }

  @override
  void dispose() {
    getIt<NotificationService>().onTap = null;
    super.dispose();
  }

  void _handlePushTap(Map<String, dynamic> data) {
    final router = AppRouter.router;
    final type = data['type']?.toString() ?? '';
    final contentUrl = data['contentUrl']?.toString();
    final provider = data['provider']?.toString();

    switch (type) {
      case 'system_comment_reply':
      case 'system_comment_like':
        if (contentUrl != null && contentUrl.isNotEmpty) {
          router.push(
            '/detail',
            extra: DetailArgs(contentUrl: contentUrl, provider: provider),
          );
        } else {
          router.push('/notifications');
        }
      case 'system_ban':
        getIt<AuthBloc>().add(AuthSessionExpired());
        router.go('/login');
      case 'system_unban':
      case 'admin_broadcast':
      case 'admin_direct':
        router.push('/notifications');
      default:
        router.push('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(AppConstants.baseUrl);
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<ViewAllBloc>(create: (_) => getIt<ViewAllBloc>()),
        BlocProvider<HomeBloc>(create: (_) => getIt<HomeBloc>()),
        BlocProvider<SearchBloc>(create: (_) => getIt<SearchBloc>()),
        BlocProvider<ProviderBloc>(
          create: (_) => getIt<ProviderBloc>()..add(const ProviderLoad()),
        ),
      ],
      child: MaterialApp.router(
        title: 'app_name'.tr(),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}
