import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/features/splash/presentation/widgets/apple_splash.dart';
import 'package:soplay/features/splash/presentation/widgets/netflix_splash.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final bool _showNetflix;

  @override
  void initState() {
    super.initState();
    _showNetflix = Random().nextBool();
  }

  void _onComplete() {
    if (!mounted) return;
    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    return _showNetflix
        ? NetflixSplash(onComplete: _onComplete)
        : AppleSplash(onComplete: _onComplete);
  }
}
