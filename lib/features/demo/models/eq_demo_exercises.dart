import 'dart:math';

import '../../../core/constants/app_assets.dart';
import 'category_demo_content.dart';

class EqDemoExercise {
  const EqDemoExercise({
    required this.id,
    required this.introSubtitle,
    required this.question,
    required this.sourceAsset,
    required this.variantAsset,
    required this.correctAsset,
    required this.feedbackBody,
    required this.feedbackIncorrectBody,
  });

  final String id;
  final String introSubtitle;
  final String question;
  final String sourceAsset;
  final String variantAsset;
  final String correctAsset;
  final String feedbackBody;
  final String feedbackIncorrectBody;
}

abstract final class EqDemoExercises {
  static const exercises = <EqDemoExercise>[
    EqDemoExercise(
      id: 'EQ_01',
      introSubtitle: 'Compara una guitarra natural con una versión procesada.',
      question: '¿Cuál conserva mejor su naturalidad?',
      sourceAsset: AppAssets.guitarAcoustic01,
      variantAsset: AppAssets.guitarAcoustic01BoomyDark,
      correctAsset: AppAssets.guitarAcoustic01,
      feedbackBody:
          'Correcto. La versión natural conserva el balance original del instrumento.',
      feedbackIncorrectBody:
          'Escucha nuevamente el exceso de graves y la pérdida de claridad en la otra versión.',
    ),
    EqDemoExercise(
      id: 'EQ_02',
      introSubtitle: 'Compara una voz natural con una versión procesada.',
      question: '¿Cuál suena más clara?',
      sourceAsset: AppAssets.voiceNarration01,
      variantAsset: AppAssets.voiceNarration01Muddy,
      correctAsset: AppAssets.voiceNarration01,
      feedbackBody: 'Correcto. La voz mantiene mejor definición e inteligibilidad.',
      feedbackIncorrectBody:
          'Escucha nuevamente cómo el exceso de medios bajos afecta la claridad.',
    ),
    EqDemoExercise(
      id: 'EQ_03',
      introSubtitle: 'Compara una mezcla instrumental natural con una versión procesada.',
      question: '¿Cuál suena más equilibrada?',
      sourceAsset: AppAssets.musicInstrumental01,
      variantAsset: AppAssets.musicInstrumental01Harsh,
      correctAsset: AppAssets.musicInstrumental01,
      feedbackBody:
          'Correcto. La mezcla conserva un balance más natural entre frecuencias.',
      feedbackIncorrectBody:
          'Escucha nuevamente la agresividad de las frecuencias altas.',
    ),
    EqDemoExercise(
      id: 'EQ_04',
      introSubtitle: 'Compara una voz natural con una versión con medios atenuados.',
      question: '¿Cuál tiene mejor presencia?',
      sourceAsset: AppAssets.voiceNarration01,
      variantAsset: AppAssets.voiceNarration01Scooped,
      correctAsset: AppAssets.voiceNarration01,
      feedbackBody: 'Correcto. La voz conserva mejor presencia y definición.',
      feedbackIncorrectBody:
          'Escucha nuevamente qué versión se percibe más cercana y definida.',
    ),
    EqDemoExercise(
      id: 'EQ_05',
      introSubtitle: 'Compara una guitarra natural con una versión procesada.',
      question: '¿Cuál perdió demasiado cuerpo?',
      sourceAsset: AppAssets.guitarAcoustic01,
      variantAsset: AppAssets.guitarAcoustic01Thin,
      correctAsset: AppAssets.guitarAcoustic01Thin,
      feedbackBody:
          'Correcto. Esa versión perdió demasiado contenido de bajas frecuencias.',
      feedbackIncorrectBody:
          'Escucha nuevamente cuál de las dos versiones se percibe más delgada.',
    ),
  ];

  static CategoryDemoContent toDemoContent(
    EqDemoExercise exercise, {
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
      feedbackTitle: 'Buen oído.',
      feedbackBody: exercise.feedbackBody,
      feedbackIncorrectBody: exercise.feedbackIncorrectBody,
    );
  }
}
