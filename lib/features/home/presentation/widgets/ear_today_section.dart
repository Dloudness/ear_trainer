import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/section_header.dart';

class EarTodaySection extends StatelessWidget {
  const EarTodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Tu oído hoy',
          subtitle: 'Una lectura breve de tu sesión',
        ),
        const SizedBox(height: 16),
        GlassPanel(
          accent: AppColors.cyan,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 18,
                    color: AppColors.cyan.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sensación auditiva',
                    style: AppTypography.caption.copyWith(color: AppColors.cyan),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                MockSession.completedExerciseCount == 0
                    ? 'Empieza tu primer ejercicio'
                    : 'Tu precisión global es ${MockSession.globalAccuracyPercent}%.',
                style: AppTypography.tagline(16),
              ),
              const SizedBox(height: 8),
              Text(
                MockSession.completedExerciseCount == 0
                    ? 'Completa un ejercicio para ver tu lectura auditiva.'
                    : 'Has completado ${MockSession.completedExerciseCount} ejercicios.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
