import 'package:go_router/go_router.dart';
import 'package:soplay/features/auth/presentation/pages/login_page.dart';
import 'package:soplay/features/auth/presentation/pages/register_page.dart';
import 'package:soplay/features/main/presentation/pages/main_page.dart';
import 'package:soplay/features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
}
