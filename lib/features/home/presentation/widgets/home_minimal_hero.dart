import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../models/app_language.dart';
import '../widgets/hero_section.dart';
import '../widgets/home_top_bar.dart';

/// Minimal cinematic hero — logo, tagline, single CTA, generous spacing.
class HomeMinimalHero extends StatelessWidget {
  const HomeMinimalHero({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.onStart,
    required this.scale,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback onStart;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: math.min(viewportHeight * 0.72, 560),
      child: Column(
        children: [
          HomeTopBar(
            language: language,
            onLanguageChanged: onLanguageChanged,
          ),
          const Spacer(flex: 2),
          Tagline(taglineSize: 20 * scale),
          const Spacer(flex: 3),
          SizedBox(
            width: 220,
            child: GradientButton(
              label: 'COMENZAR',
              compact: true,
              onPressed: onStart,
            ),
          ),
          const Spacer(flex: 2),
          Text(
            'Desliza para explorar',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
