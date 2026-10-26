import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../home/presentation/widgets/hero_section.dart';

/// Emotional entry point — NOT the training home.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: BreathingGlow(
                color: AppColors.purple,
                minOpacity: 0.05,
                maxOpacity: 0.11,
                child: const EarLogo(size: 256),
              ),
            ),
            const SizedBox(height: 24),
            Tagline(taglineSize: 20),
            const SizedBox(height: 20),
            Text(
              'Entrenamiento auditivo inmersivo.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(flex: 4),
            SizedBox(
              width: 240,
              child: GradientButton(
                label: 'COMENZAR',
                compact: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.onboarding),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
