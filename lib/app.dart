import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_bloc.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_bloc.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_event.dart';
import 'package:soplay/features/search/presentation/blocs/search_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home/home_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
        BlocProvider<ViewAllBloc>(create: (_) => getIt<ViewAllBloc>()),
        BlocProvider<HomeBloc>(create: (_) => getIt<HomeBloc>()),
        BlocProvider<SearchBloc>(create: (_) => getIt<SearchBloc>()),
        BlocProvider<ProviderBloc>(
          create: (_) => getIt<ProviderBloc>()..add(const ProviderLoad()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Soplay',
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
