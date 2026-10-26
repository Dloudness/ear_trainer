import 'dart:math';

import '../../../core/constants/app_assets.dart';
import 'category_demo_content.dart';

class EscuchaRealExercise {
  const EscuchaRealExercise({
    required this.id,
    required this.introSubtitle,
    required this.question,
    required this.videoAsset,
    required this.sourceAsset,
    required this.variantAsset,
    required this.correctAsset,
    required this.feedbackBody,
    required this.feedbackIncorrectBody,
  });

  final String id;
  final String introSubtitle;
  final String question;
  final String videoAsset;
  final String sourceAsset;
  final String variantAsset;
  final String correctAsset;
  final String feedbackBody;
  final String feedbackIncorrectBody;
}

abstract final class EscuchaRealExercises {
  static const exercises = <EscuchaRealExercise>[
    EscuchaRealExercise(
      id: 'REAL_01',
      introSubtitle: 'Observa la escena y compara cómo cambia la emoción.',
      question: '¿Qué versión genera mayor tensión?',
      videoAsset: AppAssets.sceneGymDark,
      sourceAsset: AppAssets.musicEpicStrings01,
      variantAsset: AppAssets.musicTensionStrings01,
      correctAsset: AppAssets.musicTensionStrings01,
      feedbackBody:
          'Correcto. Las cuerdas tensas y la armonía generan una sensación mayor de incertidumbre y tensión.',
      feedbackIncorrectBody:
          'Escucha nuevamente cómo la instrumentación modifica la emoción de la escena.',
    ),
    EscuchaRealExercise(
      id: 'REAL_02',
      introSubtitle: 'Observa el entorno y elige el ambiente más coherente.',
      question: '¿Qué ambiente transmite mejor la sensación de este lugar?',
      videoAsset: AppAssets.sceneGirlField01,
      sourceAsset: AppAssets.ambientFieldBirds01,
      variantAsset: AppAssets.ambientFieldColdRain01,
      correctAsset: AppAssets.ambientFieldBirds01,
      feedbackBody:
          'Correcto. El ambiente abierto y los sonidos naturales mantienen coherencia con el entorno visual.',
      feedbackIncorrectBody:
          'Observa nuevamente la escena y analiza qué ambiente corresponde mejor al lugar.',
    ),
  ];

  static CategoryDemoContent toDemoContent(
    EscuchaRealExercise exercise, {
    Random? random,
  }) {
    final swap = (random ?? Random()).nextBool();
    final assetA = swap ? exercise.variantAsset : exercise.sourceAsset;
    final assetB = swap ? exercise.sourceAsset : exercise.variantAsset;
    final correctOption = exercise.correctAsset == assetA ? 'A' : 'B';

    return CategoryDemoContent(
      introTitle: 'Escucha atentamente.',
      introSubtitle: exercise.introSubtitle,
      listenHint: 'Escucha ambas versiones antes de responder.',
      optionALabel: 'ESCUCHAR A',
      optionBLabel: 'ESCUCHAR B',
      chooseALabel: 'MEZCLA A',
      chooseBLabel: 'MEZCLA B',
      question: exercise.question,
      correctOption: correctOption,
      audioAssetA: assetA,
      audioAssetB: assetB,
      videoAsset: exercise.videoAsset,
      feedbackTitle: 'Buen oído.',
      feedbackBody: exercise.feedbackBody,
      feedbackIncorrectBody: exercise.feedbackIncorrectBody,
    );
  }
}
