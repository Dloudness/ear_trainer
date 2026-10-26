import 'package:flutter/material.dart';

import '../../../onboarding/models/onboarding_option.dart';
import '../../models/module_exercise_catalog.dart';
import '../widgets/module_exercise_list_card.dart';
import '../widgets/module_screen_layout.dart';

class MusicalTrainingScreen extends StatelessWidget {
  const MusicalTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = ModuleExerciseCatalog.forCategory(
      OnboardingOption.entrenamientoMusical,
    );

    return ModuleScreenLayout(
      title: 'Entrenamiento Musical',
      subtitle: 'Intervalos, acordes y percepción armónica.',
      children: [
        for (final entry in exercises)
          ModuleExerciseListCard(
            entry: entry,
            accent: const Color(0xFF818CF8),
          ),
      ],
    );
  }
}
