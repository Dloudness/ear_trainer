import 'dart:math';

import '../../../core/session/mock_session.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import 'practice_levels.dart';

/// Diseño sonoro practices (Premium). Exercises come from
/// tools/generate_sound_design.dart; tags.drill says which practice.
enum SoundDesignDrill { ambience, take, mix, reverb, continuity }

abstract final class SoundDesignPractice {
  static const module = 'disenoSonoro';

  static String title(SoundDesignDrill drill) => switch (drill) {
    SoundDesignDrill.ambience => '¿Qué ambiente es?',
    SoundDesignDrill.take => '¿Qué le pasa a esta toma?',
    SoundDesignDrill.mix => '¿Qué ajustarías en esta mezcla?',
    SoundDesignDrill.reverb => '¿Cuánta reverberación tiene?',
    SoundDesignDrill.continuity => '¿Se pueden pegar estas tomas?',
  };

  static String detail(SoundDesignDrill drill) => switch (drill) {
    SoundDesignDrill.ambience =>
      'Escucha un lugar y reconócelo entre otros que suenan parecido.',
    SoundDesignDrill.take =>
      'Una toma de diálogo con un problema sutil, o limpia. Escúchala como sonidista.',
    SoundDesignDrill.mix =>
      'Diálogo con música de cine: ¿bajarías la música, la subirías o está bien?',
    SoundDesignDrill.reverb =>
      'Una voz o un foley con la sala seca, con un poco de sala o con mucha.',
    SoundDesignDrill.continuity =>
      'Dos tomas pegadas en la edición: ¿el ruido de fondo sigue igual en el corte?',
  };

  /// Exercises of [drill] the listener can open.
  static List<Exercise> of(SoundDesignDrill drill) {
    return [
      for (final exercise in ExerciseRepository.instance.byModule(module))
        if (exercise.tags['drill'] == drill.name &&
            ExerciseRepository.instance.isPlayable(exercise) &&
            MockSession.allowsAccess(exercise.access))
          exercise,
    ];
  }

  /// Next exercise; none repeats until the rest have come out.
  static Exercise? pick(
    SoundDesignDrill drill, {
    String? avoidId,
    Random? random,
  }) {
    return NoRepeatPicker.pick(
      'sound_design_${drill.name}',
      of(drill),
      avoidId: avoidId,
      random: random,
    );
  }
}
