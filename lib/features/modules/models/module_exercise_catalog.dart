import '../../../core/router/app_routes.dart';
import '../../demo/models/category_demo_content.dart';
import '../../demo/models/eq_demo_exercises.dart';
import '../../demo/models/escucha_real_exercises.dart';
import '../../onboarding/models/onboarding_option.dart';

class ModuleExerciseEntry {
  const ModuleExerciseEntry({
    required this.label,
    required this.title,
    required this.category,
    required this.exerciseIndex,
  });

  final String label;
  final String title;
  final OnboardingOption category;
  final int exerciseIndex;
}

abstract final class ModuleExerciseCatalog {
  static List<ModuleExerciseEntry> forCategory(OnboardingOption category) {
    return switch (category) {
      OnboardingOption.ecualizacionFrecuencias => [
          for (var i = 0; i < EqDemoExercises.exercises.length; i++)
            ModuleExerciseEntry(
              label: 'Ejercicio ${i + 1}',
              title: EqDemoExercises.exercises[i].question,
              category: category,
              exerciseIndex: i,
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
          ModuleExerciseEntry(
            label: 'Ejercicio 1',
            title: CategoryDemoContent.forCategory(category).question,
            category: category,
            exerciseIndex: 0,
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
