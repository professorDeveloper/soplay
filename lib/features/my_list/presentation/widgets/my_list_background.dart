import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class MyListBackground extends StatelessWidget {
  const MyListBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF161616), AppColors.background, const Color(0xFF101010)],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
