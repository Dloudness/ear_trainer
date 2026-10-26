import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../models/placeholder_exercise_args.dart';

class PlaceholderExerciseCard extends StatelessWidget {
  const PlaceholderExerciseCard({
    super.key,
    required this.title,
    required this.comingSoon,
    this.accent,
    this.moduleTitle,
  });

  final String title;
  final String comingSoon;
  final Color? accent;
  final String? moduleTitle;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.blue;

    return GlassPanel(
      accent: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.35),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'ESCUCHAR',
            compact: true,
            icon: Icons.play_arrow_rounded,
            emphasized: true,
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.exercise,
                arguments: PlaceholderExerciseArgs(
                  title: title,
                  comingSoon: comingSoon,
                  accent: color,
                  moduleTitle: moduleTitle,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            comingSoon,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
