import 'package:flutter/material.dart';
import 'package:soplay/core/theme/app_colors.dart';

class MyListBackground extends StatelessWidget {
  const MyListBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF161616), AppColors.background, Color(0xFF101010)],
          stops: [0, 0.42, 1],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
