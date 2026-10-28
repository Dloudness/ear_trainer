import 'dart:math';

import '../../exercises/models/exercise.dart';
import 'category_demo_content.dart';

abstract final class ExerciseDemoMapper {
  static CategoryDemoContent toContent(
    Exercise exercise, {
    Random? random,
  }) {
    if (exercise.type != 'ab_compare') {
      throw UnsupportedError(
        'ExerciseDemoMapper solo cubre ab_compare (${exercise.id}).',
      );
    }

    final rng = random ?? Random();
    final presented = exercise.present(random: rng);
    if (presented.length != 2 ||
        presented[0].path == null ||
        presented[1].path == null) {
      throw StateError(
        'El ejercicio ${exercise.id} necesita dos opciones con audio.',
      );
    }

    final swap = rng.nextBool();
    final optionA = swap ? presented[1] : presented[0];
    final optionB = swap ? presented[0] : presented[1];

    return CategoryDemoContent(
      introTitle: 'Escucha atentamente.',
      introSubtitle: exercise.introSubtitle ?? '',
      listenHint: 'Escucha ambas versiones antes de responder.',
      optionALabel: 'ESCUCHAR A',
      optionBLabel: 'ESCUCHAR B',
      chooseALabel: 'MEZCLA A',
      chooseBLabel: 'MEZCLA B',
      question: exercise.question,
      correctOption: exercise.correct == optionA.id ? 'A' : 'B',
      audioAssetA: optionA.path,
      audioAssetB: optionB.path,
      feedbackTitle: 'Buen oído.',
      feedbackBody: exercise.explanation,
      feedbackIncorrectBody:
          exercise.explanationIncorrect ?? exercise.explanation,
    );
  }
}
