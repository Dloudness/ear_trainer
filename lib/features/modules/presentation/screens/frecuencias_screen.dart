import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/models/onboarding_option.dart';
import '../../models/module_exercise_catalog.dart';
import '../widgets/module_exercise_list_card.dart';
import '../widgets/module_screen_layout.dart';

class FrecuenciasScreen extends StatelessWidget {
  const FrecuenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = ModuleExerciseCatalog.forCategory(
      OnboardingOption.ecualizacionFrecuencias,
    );

    return ModuleScreenLayout(
      title: 'Frecuencias',
      subtitle: 'Detecta rangos, balance tonal y fatiga auditiva.',
      children: [
        for (final entry in exercises)
          ModuleExerciseListCard(
            entry: entry,
            accent: AppColors.cyan,
          ),
      ],
    );
  }
}
