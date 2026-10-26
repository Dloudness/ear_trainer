import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';

/// Teaser shown in light mode — full continue training unlocks after login.
class LightContinueTrainingSection extends StatelessWidget {
  const LightContinueTrainingSection({super.key, this.onLoginTap});

  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Continuar entrenando',
          subtitle: 'Tu evolución te espera al iniciar sesión',
        ),
        const SizedBox(height: 16),
        GlassPanel(
          accent: AppColors.blue,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 22,
                    color: AppColors.blue.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: AppColors.blue.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Progreso no guardado',
                              style: AppTypography.caption.copyWith(color: AppColors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          MockSession.continueTraining.hasHistory
                              ? MockSession.continueTraining.title
                              : 'Empieza tu primer ejercicio',
                          style: AppTypography.cardTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explora libremente. Inicia sesión para retomar donde lo dejaste.',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'DESBLOQUEAR',
                compact: true,
                onPressed: onLoginTap ?? () => AppNavigator.openLogin(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
