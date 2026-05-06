import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/features/splash/presentation/widgets/netflix_splash.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  void _onComplete() {
    if (!mounted) return;
    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    return NetflixSplash(onComplete: _onComplete);
  }
}
