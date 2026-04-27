import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppleSplash extends StatefulWidget {
  const AppleSplash({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<AppleSplash> createState() => _AppleSplashState();
}

class _AppleSplashState extends State<AppleSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _shimmer;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
      ),
    );
    _setup();
    _run();
  }

  void _setup() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      ),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.24, curve: Curves.easeIn),
      ),
    );

    _shimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.56, curve: Curves.easeInOut),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 120));
    await _controller.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Center(
              child: Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) {
                          final centerX =
                              -bounds.width +
                              _shimmer.value * 3.0 * bounds.width;
                          return LinearGradient(
                            colors: const [
                              Color(0xFFAAAAAA),
                              Color(0xFFE8E8E8),
                              Colors.white,
                              Color(0xFFE8E8E8),
                              Color(0xFFAAAAAA),
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ).createShader(
                            Rect.fromCenter(
                              center: Offset(centerX, bounds.height / 2),
                              width: bounds.width * 0.55,
                              height: bounds.height,
                            ),
                          );
                        },
                        child: const Text(
                          'soplay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 10,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(width: 36, height: 0.5, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
