import 'package:go_router/go_router.dart';
import 'package:soplay/features/auth/presentation/pages/login_page.dart';
import 'package:soplay/features/auth/presentation/pages/register_page.dart';
import 'package:soplay/features/home/domain/entities/view_all.dart';
import 'package:soplay/features/main/presentation/pages/main_page.dart';
import 'package:soplay/features/splash/presentation/pages/splash_page.dart';

import '../../features/home/presentation/pages/home_view_all_page.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/view-all',
        builder: (context, state) {
          final args = state.extra as ViewAllEntity;
          final slug = args.slug;
          final title = slug.isEmpty ? args.type : args.slug;
          return HomeViewAllPage(
            keyCat: args.type,
            slug: args.slug,
            title: title,
          );
        },
      ),
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/main', builder: (context, state) => const MainPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
}
