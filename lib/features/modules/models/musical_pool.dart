import 'dart:math';

import '../../../core/session/mock_session.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import '../../onboarding/models/onboarding_option.dart';

enum MusicalPool { intervals, chords }

abstract final class MusicalPools {
  static const intervalsTitle = 'Intervalos';
  static const chordsTitle = 'Acordes';

  static String title(MusicalPool pool) {
    return switch (pool) {
      MusicalPool.intervals => intervalsTitle,
      MusicalPool.chords => chordsTitle,
    };
  }

  static String lockMessage(MusicalPool pool) {
    return switch (pool) {
      MusicalPool.intervals => 'Se desbloquea con una cuenta.',
      MusicalPool.chords => 'Se desbloquea con premium.',
    };
  }

  static List<Exercise> ofType(MusicalPool pool) {
    final type = switch (pool) {
      MusicalPool.intervals => 'interval_quality',
      MusicalPool.chords => 'chord_quality',
    };
    final module = OnboardingOption.entrenamientoMusical.name;
    return [
      for (final exercise in ExerciseRepository.instance.byModule(module))
        if (exercise.type == type &&
            ExerciseRepository.instance.isPlayable(exercise))
          exercise,
    ];
  }

  static List<Exercise> unlocked(MusicalPool pool) {
    return [
      for (final exercise in ofType(pool))
        if (MockSession.allowsAccess(exercise.access)) exercise,
    ];
  }

  static bool isCardLocked(MusicalPool pool) => unlocked(pool).isEmpty;

  static List<Exercise> drawable(MusicalPool pool) {
    final open = unlocked(pool);
    if (MockSession.hasAccount || MockSession.hasPremium) return open;
    final done = MockSession.completedExercises.map((item) => item.id).toSet();
    return [
      for (final exercise in open)
        if (!done.contains(exercise.id)) exercise,
    ];
  }

  static bool needsAccountPrompt(MusicalPool pool) {
    return !MockSession.hasAccount &&
        !MockSession.hasPremium &&
        unlocked(pool).isNotEmpty &&
        drawable(pool).isEmpty;
  }

  static Exercise? pick(
    MusicalPool pool, {
    String? avoidId,
    Random? random,
  }) {
    final rng = random ?? Random();
    var list = drawable(pool);
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
