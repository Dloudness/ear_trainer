import 'dart:convert';
import 'dart:math';

import 'package:ear_trainer/features/demo/models/exercise_demo_mapper.dart';
import 'package:ear_trainer/features/exercises/data/exercise_repository.dart';
import 'package:ear_trainer/features/exercises/models/exercise.dart';
import 'package:ear_trainer/features/modules/models/musical_sections.dart';
import 'package:ear_trainer/features/modules/presentation/screens/frecuencias_screen.dart';
import 'package:ear_trainer/features/modules/presentation/screens/musical_training_screen.dart';
import 'package:ear_trainer/features/onboarding/models/onboarding_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> eqExercises;

  setUpAll(() async {
    await ExerciseRepository.instance.load();
    eqExercises = ExerciseRepository.instance.byModule(
      OnboardingOption.ecualizacionFrecuencias.name,
    );
  });

  test('loads the five EQ exercises with their original copy', () {
    expect(eqExercises.map((exercise) => exercise.id), [
      'EQ_01',
      'EQ_02',
      'EQ_03',
      'EQ_04',
      'EQ_05',
    ]);
    expect(
      eqExercises.map((exercise) => exercise.question),
      [
        '¿Cuál conserva mejor su naturalidad?',
        '¿Cuál suena más clara?',
        '¿Cuál suena más equilibrada?',
        '¿Cuál tiene mejor presencia?',
        '¿Cuál perdió demasiado cuerpo?',
      ],
    );

    final thin = eqExercises.last;
    expect(thin.correct, 'processed');
    expect(
      thin.options.firstWhere((option) => option.id == 'processed').path,
      'assets/eq/guitar_acoustic_01_thin.wav',
    );
    expect(ExerciseRepository.parse(_encodedExercises(eqExercises)).warnings, isEmpty);
  });

  test('A/B assignment still follows a single nextBool swap', () {
    for (final exercise in eqExercises) {
      final source = exercise.options.first;
      final variant = exercise.options[1];
      final swap = Random(7).nextBool();
      final content = ExerciseDemoMapper.toContent(
        exercise,
        random: Random(7),
      );
      final assetA = swap ? variant.path : source.path;
      final assetB = swap ? source.path : variant.path;

      expect(content.audioAssetA, assetA);
      expect(content.audioAssetB, assetB);
      expect(
        content.correctOption,
        exercise.correct == (swap ? variant.id : source.id) ? 'A' : 'B',
      );
      expect(content.choiceA, 'MEZCLA A');
      expect(content.choiceB, 'MEZCLA B');
      expect(content.optionALabel, 'ESCUCHAR A');
      expect(content.optionBLabel, 'ESCUCHAR B');
      expect(content.introTitle, 'Escucha atentamente.');
      expect(content.listenHint, 'Escucha ambas versiones antes de responder.');
      expect(content.feedbackTitle, 'Buen oído.');
      expect(content.introSubtitle, exercise.introSubtitle);
      expect(content.feedbackBody, exercise.explanation);
      expect(content.feedbackIncorrectBody, exercise.explanationIncorrect);
      expect(content.singleListen, isFalse);
    }
  });

  test('maxOptions keeps the correct option and fills random distractors', () {
    const exercise = Exercise(
      id: 'INT_01',
      module: 'entrenamientoMusical',
      type: 'interval_quality',
      audio: ExerciseAudio(source: 'asset', path: 'assets/musical/interval.wav'),
      question: '¿Qué intervalo escuchas?',
      options: [
        ExerciseOption(id: 'min2', label: '2da menor'),
        ExerciseOption(id: 'maj2', label: '2da mayor'),
        ExerciseOption(id: 'min3', label: '3ra menor'),
        ExerciseOption(id: 'maj3', label: '3ra mayor'),
      ],
      maxOptions: 3,
      correct: 'min3',
      difficulty: 'beginner',
      explanation: 'Es una tercera menor.',
      tags: {},
      access: 'free',
    );

    final presented = exercise.present(random: Random(1));
    expect(presented, hasLength(3));
    expect(presented.map((option) => option.id), contains('min3'));
    expect(presented.map((option) => option.id).toSet(), hasLength(3));

    const stored = Exercise(
      id: 'INT_01',
      module: 'entrenamientoMusical',
      type: 'interval_quality',
      audio: ExerciseAudio(source: 'asset', path: 'assets/musical/interval.wav'),
      question: '¿Qué intervalo escuchas?',
      options: [
        ExerciseOption(id: 'min2', label: '2da menor'),
        ExerciseOption(id: 'maj2', label: '2da mayor'),
        ExerciseOption(id: 'min3', label: '3ra menor'),
        ExerciseOption(id: 'maj3', label: '3ra mayor'),
      ],
      correct: 'min3',
      difficulty: 'beginner',
      explanation: 'Es una tercera menor.',
      tags: {},
      access: 'free',
    );
    expect(
      stored.present(random: Random(1)).map((option) => option.id),
      ['min2', 'maj2', 'min3', 'maj3'],
    );
  });

  test('parse warns about duplicate ids and keeps the first entry', () {
    final decoded = jsonDecode(_encodedExercises(eqExercises)) as Map<String, dynamic>;
    final list = decoded['exercises'] as List<dynamic>;
    final parsed = ExerciseRepository.parse(
      jsonEncode({
        'exercises': [list.first, list.first],
      }),
    );

    expect(parsed.exercises, hasLength(1));
    expect(parsed.exercises.single.id, 'EQ_01');
    expect(parsed.warnings.single, contains('id duplicado "EQ_01"'));
  });

  test('missing audio paths are reported', () async {
    const exercise = Exercise(
      id: 'EQ_MISSING',
      module: 'ecualizacionFrecuencias',
      type: 'ab_compare',
      audio: ExerciseAudio(source: 'asset', path: 'assets/eq/missing.wav'),
      question: '¿Cuál?',
      options: [
        ExerciseOption(id: 'natural', label: 'Natural', path: 'assets/eq/missing.wav'),
        ExerciseOption(
          id: 'processed',
          label: 'Procesada',
          path: 'assets/eq/also_missing.wav',
        ),
      ],
      correct: 'natural',
      difficulty: 'beginner',
      explanation: 'Correcto.',
      tags: {},
      access: 'free',
    );

    final warnings = await ExerciseRepository.missingAudioWarnings([exercise]);
    expect(warnings, hasLength(2));
    expect(warnings.first, contains('EQ_MISSING'));
    expect(warnings.first, contains('assets/eq/missing.wav'));
    expect(warnings.last, contains('assets/eq/also_missing.wav'));
  });

  test('musical exercises are grouped and the mock MUS_01 is gone', () {
    final sections = MusicalSections.all();
    expect(sections.map((section) => section.id), [
      MusicalSectionId.intervalsAscending,
      MusicalSectionId.intervalsDescending,
      MusicalSectionId.intervalsHarmonic,
      MusicalSectionId.triads,
      MusicalSectionId.sevenths,
      MusicalSectionId.inversions,
    ]);
    expect(sections.map((section) => section.exercises.length), [
      12,
      12,
      12,
      24,
      12,
      25,
    ]);
    for (final section in sections) {
      final ranks = section.exercises.map((exercise) {
        return switch (exercise.difficulty) {
          'beginner' => 0,
          'intermediate' => 1,
          'advanced' => 2,
          _ => 9,
        };
      });
      expect(ranks, orderedEquals([...ranks]..sort()));
    }
    expect(
      sections.expand((section) => section.exercises).map((e) => e.id),
      isNot(contains('MUS_01')),
    );
  });

  testWidgets('Frecuencias lists the five JSON questions', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FrecuenciasScreen()));
    await tester.pump();

    expect(find.text('¿Cuál conserva mejor su naturalidad?'), findsOneWidget);
    expect(find.text('¿Cuál perdió demasiado cuerpo?'), findsOneWidget);
    expect(find.text('Ejercicio 5'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Musical module shows six sections instead of the mock', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MusicalTrainingScreen()));
    await tester.pump();

    expect(find.text('Intervalos ascendentes'), findsOneWidget);
    expect(find.text('Intervalos descendentes'), findsOneWidget);
    expect(find.text('Intervalos armónicos'), findsOneWidget);
    expect(find.text('Acordes · tríadas'), findsOneWidget);
    expect(find.text('Acordes · séptimas'), findsOneWidget);
    expect(find.text('Acordes · inversiones'), findsOneWidget);
    expect(find.text('3ª mayor'), findsNothing);
    expect(find.text('5ª justa'), findsNothing);
    expect(find.text('VER LISTA'), findsNWidgets(6));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

String _encodedExercises(List<Exercise> exercises) {
  return jsonEncode({
    'exercises': [
      for (final exercise in exercises)
        {
          'id': exercise.id,
          'module': exercise.module,
          'type': exercise.type,
          'audio': {
            'source': exercise.audio.source,
            'path': exercise.audio.path,
          },
          'question': exercise.question,
          'options': [
            for (final option in exercise.options)
              {
                'id': option.id,
                'label': option.label,
                'path': option.path,
              },
          ],
          'correct': exercise.correct,
          'difficulty': exercise.difficulty,
          'explanation': exercise.explanation,
          'explanationIncorrect': exercise.explanationIncorrect,
          'introSubtitle': exercise.introSubtitle,
          'tags': exercise.tags,
          'access': exercise.access,
        },
    ],
  });
}
