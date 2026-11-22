import 'dart:math';

import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import '../../onboarding/models/onboarding_option.dart';

enum EqSource { music, pink }

/// Random practice for one advanced EQ source.
///
/// Each exercise is one frequency and one gain. The next draw skips the
/// adjustment just heard when another one is available.
abstract final class EqPractice {
  static const musicTitle = 'Música';
  static const pinkTitle = 'Ruido rosa';

  static String title(EqSource source) {
    return switch (source) {
      EqSource.music => musicTitle,
      EqSource.pink => pinkTitle,
    };
  }

  static String detail(EqSource source) {
    return switch (source) {
      EqSource.music =>
        'Fragmento con una sola banda identificable en el ejemplo.',
      EqSource.pink => 'Ruido rosa con el boost de una banda ya aplicado.',
    };
  }

  static List<Exercise> of(EqSource source) {
    final module = OnboardingOption.ecualizacionFrecuencias.name;
    return [
      for (final exercise in ExerciseRepository.instance.byModule(module))
        if (exercise.type == 'eq_band' &&
            exercise.tags['source'] == source.name &&
            ExerciseRepository.instance.isPlayable(exercise))
          exercise,
    ];
  }

  static Exercise? pick(EqSource source, {String? avoidId, Random? random}) {
    final rng = random ?? Random();
    var list = of(source);
    if (avoidId != null && list.length > 1) {
      list = [
        for (final exercise in list)
          if (exercise.id != avoidId) exercise,
      ];
    }
    if (list.isEmpty) return null;
    return list[rng.nextInt(list.length)];
  }
}
