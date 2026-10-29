import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';

class ContinueTrainingSection extends StatelessWidget {
  const ContinueTrainingSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!MockSession.isLoggedIn) return const SizedBox.shrink();
    final info = MockSession.continueTraining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Continuar entrenando',
          subtitle: 'Retoma donde lo dejaste',
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
                        Text(
                          info.title,
                          style: AppTypography.cardTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${info.accuracyPercent}% precisión',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: info.totalCount == 0
                      ? 0
                      : info.completedCount / info.totalCount,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'CONTINUAR',
                compact: true,
                onPressed: () => Navigator.pushNamed(context, info.route),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
