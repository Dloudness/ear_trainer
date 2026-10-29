import '../../../core/router/app_routes.dart';
import '../../demo/models/category_demo_content.dart';
import '../../demo/models/escucha_real_exercises.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../onboarding/models/onboarding_option.dart';
import 'musical_sections.dart';

class ModuleExerciseEntry {
  const ModuleExerciseEntry({
    required this.label,
    required this.title,
    required this.category,
    required this.exerciseIndex,
    this.access,
  });

  final String label;
  final String title;
  final OnboardingOption category;
  final int exerciseIndex;
  final String? access;
}

abstract final class ModuleExerciseCatalog {
  static List<ModuleExerciseEntry> forCategory(OnboardingOption category) {
    return switch (category) {
      OnboardingOption.ecualizacionFrecuencias => [
          for (final (index, exercise) in ExerciseRepository.instance
              .byModule(category.name)
              .indexed)
            ModuleExerciseEntry(
              label: 'Ejercicio ${index + 1}',
              title: exercise.question,
              category: category,
              exerciseIndex: index,
              access: exercise.access,
            ),
        ],
      OnboardingOption.dinamicaCompresion => [
          ModuleExerciseEntry(
            label: 'Ejercicio 1',
            title: CategoryDemoContent.forCategory(category).question,
            category: category,
            exerciseIndex: 0,
          ),
        ],
      OnboardingOption.entrenamientoMusical => [
          for (final (index, exercise)
              in MusicalSections.playableExercises().indexed)
            ModuleExerciseEntry(
              label: 'Ejercicio ${index + 1}',
              title: exercise.question,
              category: category,
              exerciseIndex: index,
            ),
        ],
      OnboardingOption.escuchaReal => [
          for (var i = 0; i < EscuchaRealExercises.exercises.length; i++)
            ModuleExerciseEntry(
              label: 'Ejercicio ${i + 1}',
              title: EscuchaRealExercises.exercises[i].question,
              category: category,
              exerciseIndex: i,
            ),
        ],
    };
  }

  static String moduleRouteFor(OnboardingOption category) {
    return switch (category) {
      OnboardingOption.ecualizacionFrecuencias => AppRoutes.moduleFrecuencias,
      OnboardingOption.dinamicaCompresion => AppRoutes.moduleDinamica,
      OnboardingOption.entrenamientoMusical => AppRoutes.moduleMusical,
      OnboardingOption.escuchaReal => AppRoutes.moduleEscuchaReal,
    };
  }
}
