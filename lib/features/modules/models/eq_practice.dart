import 'dart:math';

import '../../../core/session/mock_session.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import '../../onboarding/models/onboarding_option.dart';
import 'practice_levels.dart';

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
      EqSource.pink =>
        'Ruido rosa con una banda realzada o recortada. Compáralo con el ruido rosa limpio.',
    };
  }

  /// Listens to the clean pink noise allowed at each level (0 hides it).
  static int pinkReferenceListens(int level) {
    return switch (level) {
      1 => 2,
      2 => 1,
      _ => 0,
    };
  }

  static String pinkLevelDetail(int level) {
    return switch (pinkReferenceListens(level)) {
      2 =>
        'El ejemplo pasa de limpio a ecualizado y vuelve. Ruido limpio aparte: 2 escuchas.',
      1 =>
        'El ejemplo pasa de limpio a ecualizado y vuelve. Ruido limpio aparte: 1 escucha.',
      _ => 'Sin referencia: solo el ruido ya ecualizado, sin transición.',
    };
  }

  /// Levels 1 and 2 play the example that moves clean → EQ → clean.
  static bool pinkUsesSweep(int level) => pinkReferenceListens(level) > 0;

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

  /// Next exercise; none repeats until the rest have come out.
  static Exercise? pick(EqSource source, {String? avoidId, Random? random}) {
    return NoRepeatPicker.pick(
      'eq_${source.name}',
      of(source),
      avoidId: avoidId,
      random: random,
    );
  }
}

/// Random pure-tone practice: which frequency (T1) and higher or lower (T2).
enum ToneDrill { frequency, compare }

abstract final class TonePractice {
  static String type(ToneDrill drill) => switch (drill) {
    ToneDrill.frequency => 'tone_frequency',
    ToneDrill.compare => 'tone_compare',
  };

  static String title(ToneDrill drill) => switch (drill) {
    ToneDrill.frequency => 'Frecuencia del tono',
    ToneDrill.compare => '¿Más agudo o más grave?',
  };

  static String detail(ToneDrill drill) => switch (drill) {
    ToneDrill.frequency =>
      'Escucha un tono puro e identifica su frecuencia, de 63 Hz a 16 kHz.',
    ToneDrill.compare =>
      'Escucha dos tonos seguidos y di si el segundo sube o baja.',
  };

  /// Levels of the frequency drill: octaves, then third-octave bands.
  static LevelLadder? ladder(ToneDrill drill) =>
      drill == ToneDrill.frequency ? LevelLadder.tones : null;

  static String levelDetail(int level) => level == 1
      ? 'Bandas de octava, de 63 Hz a 16 kHz.'
      : 'Tercios de octava: frecuencias vecinas, más cerca entre sí.';

  /// Exercises of [drill]; with [level], only that level (frequency drill).
  static List<Exercise> of(ToneDrill drill, {int? level}) {
    final module = OnboardingOption.ecualizacionFrecuencias.name;
    return [
      for (final exercise in ExerciseRepository.instance.byModule(module))
        if (exercise.type == type(drill) &&
            (level == null || exercise.tags['level'] == '$level') &&
            ExerciseRepository.instance.isPlayable(exercise) &&
            MockSession.allowsAccess(exercise.access))
          exercise,
    ];
  }

  /// Next exercise; none repeats until the rest have come out.
  static Exercise? pick(
    ToneDrill drill, {
    int? level,
    String? avoidId,
    Random? random,
  }) {
    return NoRepeatPicker.pick(
      'tone_${drill.name}_${level ?? 0}',
      of(drill, level: level),
      avoidId: avoidId,
      random: random,
    );
  }
}

/// Random practice for the beginner EQ level: the A/B comparisons the
/// current user has unlocked, drawn without a list screen in between.
abstract final class EqInitialPractice {
  static List<Exercise> _module() {
    return ExerciseRepository.instance.byModule(
      OnboardingOption.ecualizacionFrecuencias.name,
    );
  }

  static List<Exercise> unlocked() {
    return [
      for (final exercise in _module())
        if (exercise.type == 'ab_compare' &&
            ExerciseRepository.instance.isPlayable(exercise) &&
            MockSession.allowsAccess(exercise.access))
          exercise,
    ];
  }

  /// Index inside the EQ module, which is what the exercise screen reads.
  static int? pickIndex({String? avoidId, Random? random}) {
    final rng = random ?? Random();
    var list = unlocked();
    if (avoidId != null && list.length > 1) {
      list = [
        for (final exercise in list)
          if (exercise.id != avoidId) exercise,
      ];
    }
    if (list.isEmpty) return null;
    final picked = list[rng.nextInt(list.length)];
    final index = _module().indexWhere((item) => item.id == picked.id);
    return index < 0 ? null : index;
  }
}
