import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/models/onboarding_option.dart';
import '../../models/module_exercise_catalog.dart';
import '../widgets/module_exercise_list_card.dart';
import '../widgets/module_screen_layout.dart';

class DinamicaScreen extends StatelessWidget {
  const DinamicaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = ModuleExerciseCatalog.forCategory(
      OnboardingOption.dinamicaCompresion,
    );

    return ModuleScreenLayout(
      title: 'Dinámica',
      subtitle: 'Compresión, punch y control dinámico en la mezcla.',
      children: [
        for (final entry in exercises)
          ModuleExerciseListCard(
            entry: entry,
            accent: AppColors.orange,
          ),
      ],
    );
  }
}
