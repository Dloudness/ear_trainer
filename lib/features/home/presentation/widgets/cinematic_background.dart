import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class CinematicBackground extends StatelessWidget {
  const CinematicBackground({super.key, required this.ambient});

  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final t = ambient.value;
        final purpleGlow = 0.08 + t * 0.04;
        final warmGlow = 0.06 + (1 - t) * 0.03;

        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.3),
                  radius: 1.0,
                  colors: [
                    AppColors.purple.withValues(alpha: purpleGlow),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.1),
                  radius: 0.9,
                  colors: [
                    AppColors.blue.withValues(alpha: 0.06 + t * 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFF8C00).withValues(alpha: warmGlow),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                  stops: const [0.4, 0.72, 1.0],
                ),
              ),
            ),
          ],
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Transform.scale(
              scale: 1.06,
              child: Image.asset(
                AppAssets.bundle(AppAssets.homeBackground),
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.2),
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.48)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0614).withValues(alpha: 0.5),
                  Colors.transparent,
                  const Color(0xFF050810).withValues(alpha: 0.55),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
