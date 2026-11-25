import 'dart:math';

import '../../../core/session/mock_session.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import '../../onboarding/models/onboarding_option.dart';
import 'practice_levels.dart';

enum MusicalPool { intervals, chords, tuning, tuningContext }

abstract final class MusicalPools {
  static const intervalsTitle = 'Intervalos';
  static const chordsTitle = 'Acordes';
  static const tuningTitle = 'Afinación';
  static const tuningContextTitle = 'Afinación en contexto';

  /// "¿Por qué entrenar...?" window for the pool. Both tuning cards share
  /// the tuning one.
  static String contextId(MusicalPool pool) {
    return pool == MusicalPool.tuningContext
        ? MusicalPool.tuning.name
        : pool.name;
  }

  static const freeIntervalOrder = [
    'interval_perf8_asc_c4_01',
    'interval_perf5_asc_c4_01',
    'interval_min2_asc_c4_01',
  ];

  static String title(MusicalPool pool) {
    return switch (pool) {
      MusicalPool.intervals => intervalsTitle,
      MusicalPool.chords => chordsTitle,
      MusicalPool.tuning => tuningTitle,
      MusicalPool.tuningContext => tuningContextTitle,
    };
  }

  static String lockMessage(MusicalPool pool) {
    return switch (pool) {
      MusicalPool.intervals => 'Se desbloquea con una cuenta.',
      MusicalPool.chords => 'Se desbloquea con premium.',
      MusicalPool.tuning => 'Se desbloquea con una cuenta.',
      MusicalPool.tuningContext => 'Se desbloquea con una cuenta.',
    };
  }

  /// Instruments left out of tuning in context. Some guitar one-shots sound
  /// out of tune even after retuning (a note heard ~30 cents off in a
  /// Fa♯ mayor melody), which makes the "which note is detuned" answer
  /// ambiguous. They stay out until each guitar note is re-audited against
  /// the original recordings. Remove 'guitar' here to bring them back.
  static const tuningContextExcluded = {'guitar'};

  static List<Exercise> ofType(MusicalPool pool) {
    final type = switch (pool) {
      MusicalPool.intervals => 'interval_quality',
      MusicalPool.chords => 'chord_quality',
      MusicalPool.tuning => 'pitch_tuning',
      MusicalPool.tuningContext => 'pitch_context',
    };
    final module = OnboardingOption.entrenamientoMusical.name;
    return [
      for (final exercise in ExerciseRepository.instance.byModule(module))
        if (exercise.type == type &&
            ExerciseRepository.instance.isPlayable(exercise) &&
            !(pool == MusicalPool.tuningContext &&
                tuningContextExcluded.contains(exercise.tags['instrument'])))
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

  /// Levels of the pool, if it has them (intervals, tuning in context).
  static LevelLadder? ladder(MusicalPool pool) => switch (pool) {
    MusicalPool.intervals => LevelLadder.intervals,
    MusicalPool.tuningContext => LevelLadder.tuning,
    _ => null,
  };

  static String levelDetail(MusicalPool pool, int level) {
    if (pool == MusicalPool.intervals) {
      return switch (level) {
        1 => '2da menor, 3ra mayor, 4ta, 5ta y octava, subiendo y bajando.',
        2 => 'Los 12 intervalos de la octava, también con las notas juntas.',
        _ => 'Hasta la 10ma, con opciones que se parecen entre sí.',
      };
    }
    return switch (level) {
      1 => 'Una nota fuera de la escala o un acorde con una nota equivocada.',
      2 => 'Notas desafinadas medio semitono (50 cents).',
      _ => 'Desafinaciones finas: 25, 15 y 10 cents.',
    };
  }

  /// Listening introduction shown before the first exercise, if the pool
  /// has one.
  static String? introId(MusicalPool pool) =>
      pool == MusicalPool.intervals ? 'intervals' : null;

  /// Next exercise (at [level] when the pool has levels); none repeats
  /// until the rest have come out.
  static Exercise? pick(
    MusicalPool pool, {
    int? level,
    String? avoidId,
    Random? random,
  }) {
    var list = drawable(pool);
    if (level != null && ladder(pool) != null) {
      list = [
        for (final exercise in list)
          if (exercise.tags['level'] == '$level') exercise,
      ];
    }
    if (list.isEmpty) return null;
    if (pool == MusicalPool.intervals &&
        list.every((exercise) => exercise.access == 'free')) {
      for (final id in freeIntervalOrder) {
        for (final exercise in list) {
          if (exercise.id == id && exercise.id != avoidId) return exercise;
        }
      }
    }
    return NoRepeatPicker.pick(
      'musical_${pool.name}_${level ?? 0}',
      list,
      avoidId: avoidId,
      random: random,
    );
  }
}
