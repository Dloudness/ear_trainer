import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../exercises/data/exercise_repository.dart';
import '../../../exercises/models/exercise.dart';
import '../../../onboarding/models/onboarding_option.dart';
import '../../models/module_exercise_catalog.dart';
import '../widgets/module_exercise_list_card.dart';
import '../widgets/module_screen_layout.dart';

/// Beginner recognition plus the existing EQ A/B comparisons.
class EqInitialScreen extends StatelessWidget {
  const EqInitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final module = OnboardingOption.ecualizacionFrecuencias.name;
    final exercises = ExerciseRepository.instance.byModule(module);
    final lessons = [
      for (final exercise in exercises)
        if (exercise.id.startsWith('EQ_INIT_')) exercise,
    ];
    final comparisons = [
      for (final exercise in exercises)
        if (exercise.type == 'ab_compare' &&
            !exercise.id.startsWith('EQ_INIT_'))
          exercise,
    ];

    return ModuleScreenLayout(
      title: 'Inicial',
      subtitle:
          'Reconoce el cambio con palabras sencillas. Las comparaciones A/B siguen disponibles.',
      children: [
        for (final exercise in lessons)
          ModuleExerciseListCard(
            entry: _entry(exercises, exercise, 'Reconocer'),
            accent: AppColors.cyan,
          ),
        for (var i = 0; i < comparisons.length; i++)
          ModuleExerciseListCard(
            entry: _entry(exercises, comparisons[i], 'Comparación ${i + 1}'),
            accent: AppColors.cyan,
          ),
      ],
    );
  }

  ModuleExerciseEntry _entry(
    List<Exercise> exercises,
    Exercise exercise,
    String label,
  ) {
    return ModuleExerciseEntry(
      label: label,
      title: exercise.question,
      category: OnboardingOption.ecualizacionFrecuencias,
      exerciseIndex: exercises.indexWhere((item) => item.id == exercise.id),
      access: exercise.access,
    );
  }
}
