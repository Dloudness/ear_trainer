import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../demo/models/demo_experience_args.dart';
import '../../models/module_exercise_catalog.dart';

class ModuleExerciseListCard extends StatelessWidget {
  const ModuleExerciseListCard({
    super.key,
    required this.entry,
    required this.accent,
  });

  final ModuleExerciseEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: AppTypography.caption.copyWith(color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
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
                AppRoutes.demo,
                arguments: DemoExperienceArgs(
                  category: entry.category,
                  exerciseIndex: entry.exerciseIndex,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
