import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ear_trainer/core/session/mock_session.dart';
import 'package:ear_trainer/features/demo/models/demo_experience_args.dart';
import 'package:ear_trainer/features/demo/models/exercise_demo_mapper.dart';
import 'package:ear_trainer/features/demo/presentation/screens/demo_experience_screen.dart';
import 'package:ear_trainer/features/exercises/data/exercise_repository.dart';
import 'package:ear_trainer/features/exercises/models/exercise.dart';
import 'package:ear_trainer/features/modules/models/eq_practice.dart';
import 'package:ear_trainer/features/modules/models/musical_pool.dart';
import 'package:ear_trainer/features/modules/models/musical_sections.dart';
import 'package:ear_trainer/features/modules/models/practice_levels.dart';
import 'package:ear_trainer/features/modules/presentation/screens/eq_band_exercise_screen.dart';
import 'package:ear_trainer/features/modules/presentation/screens/frecuencias_screen.dart';
import 'package:ear_trainer/features/modules/presentation/screens/interval_intro_screen.dart';
import 'package:ear_trainer/features/modules/presentation/screens/musical_training_screen.dart';
import 'package:ear_trainer/features/modules/presentation/screens/pink_intro_screen.dart';
import 'package:ear_trainer/features/onboarding/models/onboarding_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> eqExercises;

  setUpAll(() async {
    await ExerciseRepository.instance.load();
    eqExercises = ExerciseRepository.instance.byModule(
      OnboardingOption.ecualizacionFrecuencias.name,
    );
  });

  test('every catalog sound is compressed and exists', () {
    // WAV masters live in audio_masters/; the app plays only .m4a.
    // After a generator, run: dart run tools/compress_audio.dart
    final catalog =
        jsonDecode(File('assets/data/exercises.json').readAsStringSync());
    final paths = <String>[];
    void walk(Object? node) {
      if (node is Map) node.values.forEach(walk);
      if (node is List) node.forEach(walk);
      if (node is String && node.startsWith('assets/') && node.contains('.')) {
        final ext = node.substring(node.lastIndexOf('.'));
        if (ext != '.json' && ext != '.mp4' && ext != '.png') paths.add(node);
      }
    }

    walk(catalog);
    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(path, endsWith('.m4a'), reason: path);
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('filters: three levels, answers in the options, one variable', () {
    final all = EqPractice.of(EqSource.filter);
    expect(all.length, 60);
    final byLevel = {
      for (final level in [1, 2, 3])
        level: EqPractice.of(EqSource.filter, level: level),
    };
    expect(byLevel[1]!.length, 12);
    expect(byLevel[2]!.length, 16);
    expect(byLevel[3]!.length, 32);
    for (final exercise in all) {
      expect(exercise.id, startsWith('EQ_FILT_'));
      expect(exercise.options.map((o) => o.id), contains(exercise.correct));
      expect(exercise.referencePath, isNotNull);
      expect(exercise.referencePath, isNot(exercise.audio.path));
      expect(exercise.access, 'free', reason: 'el nivel decide Premium');
      // The intro never gives the answer away.
      for (final option in exercise.options) {
        expect(exercise.intro ?? '', isNot(contains(option.label)));
      }
    }
    // Level 1 is high-pass or low-pass at 12 dB/oct.
    for (final exercise in byLevel[1]!) {
      expect(exercise.options.length, 2);
      expect(exercise.tags['slope'], '12');
      expect(exercise.correct, exercise.tags['kind']);
    }
    // The slope drill keeps the cutoff and changes only the slope.
    final slopes = byLevel[3]!.where((e) => e.tags['drill'] == 'slope');
    expect(slopes.length, 16);
    for (final exercise in slopes) {
      expect(exercise.correct, 's${exercise.tags['slope']}');
      expect(exercise.tags['frequency'], exercise.tags['kind'] == 'hpf' ? '400' : '2000');
    }
    // A level only draws its own exercises.
    final picked = EqPractice.pick(EqSource.filter, level: 2)!;
    expect(picked.tags['level'], '2');
    expect(LevelLadder.filters.maxLevel, 3);
  });

  test('loads the five EQ exercises with their original copy', () {
    final classic = eqExercises.where(
      (exercise) => exercise.id.startsWith('EQ_0'),
    );
    expect(classic.map((exercise) => exercise.id), [
      'EQ_01',
      'EQ_02',
      'EQ_03',
      'EQ_04',
      'EQ_05',
    ]);
    expect(classic.map((exercise) => exercise.question), [
      '¿Cuál conserva mejor su naturalidad?',
      '¿Cuál suena más clara?',
      '¿Cuál suena más equilibrada?',
      '¿Cuál tiene mejor presencia?',
      '¿Cuál perdió demasiado cuerpo?',
    ]);

    final thin = classic.last;
    expect(thin.correct, 'processed');
    expect(
      thin.options.firstWhere((option) => option.id == 'processed').path,
      'assets/eq/guitar_acoustic_01_thin.m4a',
    );
    expect(
      ExerciseRepository.parse(_encodedExercises(classic.toList())).warnings,
      isEmpty,
    );
  });

  test('A/B assignment still follows a single nextBool swap', () {
    final comparisons = eqExercises.where(
      (exercise) => exercise.type == 'ab_compare',
    );
    for (final exercise in comparisons) {
      final source = exercise.options.first;
      final variant = exercise.options[1];
      final swap = Random(7).nextBool();
      final content = ExerciseDemoMapper.toContent(exercise, random: Random(7));
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
      audio: ExerciseAudio(
        source: 'asset',
        path: 'assets/musical/interval.m4a',
      ),
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
      audio: ExerciseAudio(
        source: 'asset',
        path: 'assets/musical/interval.m4a',
      ),
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
    expect(stored.present(random: Random(1)).map((option) => option.id), [
      'min2',
      'maj2',
      'min3',
      'maj3',
    ]);
  });

  test('parse warns about duplicate ids and keeps the first entry', () {
    final classic = eqExercises.where(
      (exercise) => exercise.id.startsWith('EQ_0'),
    );
    final decoded =
        jsonDecode(_encodedExercises(classic.toList())) as Map<String, dynamic>;
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
      audio: ExerciseAudio(source: 'asset', path: 'assets/eq/missing.m4a'),
      question: '¿Cuál?',
      options: [
        ExerciseOption(
          id: 'natural',
          label: 'Natural',
          path: 'assets/eq/missing.m4a',
        ),
        ExerciseOption(
          id: 'processed',
          label: 'Procesada',
          path: 'assets/eq/also_missing.m4a',
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
    expect(warnings.first, contains('assets/eq/missing.m4a'));
    expect(warnings.last, contains('assets/eq/also_missing.m4a'));
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
    // Intervals: three levels, piano and guitar (tools/generate_intervals.dart).
    expect(sections.map((section) => section.exercises.length), [
      198,
      198,
      168,
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

  testWidgets('Frecuencias Inicial goes from the explanation to an exercise', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'progress.seenEqContext': true});
    await MockSession.load();

    await tester.pumpWidget(
      MaterialApp(
        home: const FrecuenciasScreen(),
        onGenerateRoute: (settings) {
          final args = settings.arguments! as DemoExperienceArgs;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => DemoExperienceScreen(
              category: args.category,
              exerciseIndex: args.exerciseIndex,
              practice: args.practice,
            ),
          );
        },
      ),
    );
    await tester.pump();

    expect(find.text('Inicial'), findsOneWidget);
    expect(find.text('Avanzado'), findsOneWidget);
    expect(find.text('¿Por qué entrenar ecualización?'), findsNothing);

    await tester.tap(find.text('EMPEZAR').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('¿Por qué entrenar ecualización?'), findsOneWidget);
    expect(find.text('Comparación 5'), findsNothing);

    await tester.tap(find.text('ESCUCHAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Versión A'), findsOneWidget);
    expect(find.text('Tu respuesta'), findsOneWidget);
    expect(find.text('Quedan 3 escuchas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  test('the free limit counts every answer, repeats included', () async {
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
    for (var i = 0; i < 4; i++) {
      await MockSession.recordExerciseResult(exerciseId: 'EQ_01', correct: true);
    }
    expect(MockSession.answersGiven, 4);
    expect(MockSession.reachedFreeLimit, isFalse);
    await MockSession.recordExerciseResult(exerciseId: 'EQ_01', correct: false);
    expect(MockSession.reachedFreeLimit, isTrue);
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
  });

  test('EQ inicial does not repeat an exercise until all have come out', () {
    // Earlier tests may have drawn some already.
    NoRepeatPicker.reset();
    final ids = EqInitialPractice.unlocked().map((e) => e.id).toSet();
    final module = ExerciseRepository.instance.byModule(
      OnboardingOption.ecualizacionFrecuencias.name,
    );
    final drawn = <String>{};
    String? last;
    for (var i = 0; i < ids.length; i++) {
      final index = EqInitialPractice.pickIndex(
        avoidId: last,
        random: Random(i),
      )!;
      last = module[index].id;
      expect(drawn.add(last), isTrue, reason: '$last salió dos veces');
    }
    expect(drawn, ids);
  });

  testWidgets('after five free exercises the next one asks to register', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'progress.seenEqContext': true});
    await MockSession.load();
    for (final id in ['EQ_01', 'EQ_02', 'EQ_03', 'EQ_INIT_HPF']) {
      await MockSession.recordExerciseResult(exerciseId: id, correct: false);
    }
    expect(MockSession.reachedFreeLimit, isFalse);
    await MockSession.recordExerciseResult(
      exerciseId: 'EQ_INIT_LPF',
      correct: true,
    );
    expect(MockSession.reachedFreeLimit, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: const FrecuenciasScreen(),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text('ruta ${settings.name}'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('EMPEZAR').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Completaste tus ejercicios gratis'), findsOneWidget);
    await tester.tap(find.text('Ahora no'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    // No exercise opens; the visitor lands on the (guest) home instead.
    expect(find.text('¿Por qué entrenar ecualización?'), findsNothing);
    expect(find.text('ruta /home'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
  });

  test('pure tones and tuning drills are generated and playable', () async {
    final tones = eqExercises
        .where((exercise) => exercise.type.startsWith('tone_'))
        .toList();
    // Octaves 63 Hz-16 kHz × 3 loudness levels, then 26 thirds × 2.
    expect(tones.where((e) => e.tags['level'] == '1'), hasLength(27));
    expect(tones.where((e) => e.tags['level'] == '2'), hasLength(52));
    expect(tones.where((e) => e.type == 'tone_compare'), hasLength(30));
    final tuning = ExerciseRepository.instance
        .byModule(OnboardingOption.entrenamientoMusical.name)
        .where((exercise) => exercise.type == 'pitch_tuning')
        .toList();
    expect(tuning, hasLength(28));
    expect(tuning.map((e) => e.correct).toSet(), {'in_tune', 'sharp', 'flat'});

    for (final exercise in tones.where((e) => e.type == 'tone_frequency')) {
      final shown = exercise.present(random: Random(1));
      expect(shown, hasLength(4));
      expect(shown.map((o) => o.id), contains(exercise.correct));
    }
    for (final exercise in [...tones, ...tuning]) {
      expect(exercise.access, 'free');
      expect(exercise.intro, isNot(contains(exercise.correct)));
    }
    for (final drill in ToneDrill.values) {
      final picked = TonePractice.pick(drill, random: Random(2));
      expect(picked!.type, TonePractice.type(drill));
    }
    expect(MusicalPools.pick(MusicalPool.tuning, random: Random(2)), isNotNull);
    expect(
      await ExerciseRepository.missingAudioWarnings([...tones, ...tuning]),
      isEmpty,
    );
  });

  test('access is free, account or premium without revealing intros', () {
    final musical = ExerciseRepository.instance.byModule(
      OnboardingOption.entrenamientoMusical.name,
    );
    final free = musical
        .where(
          (exercise) =>
              exercise.access == 'free' && exercise.type != 'pitch_tuning',
        )
        .map((exercise) => exercise.id)
        .toSet();
    expect(free, {
      'interval_min2_asc_c4_01',
      'interval_perf5_asc_c4_01',
      'interval_perf8_asc_c4_01',
    });
    expect(
      musical
          .firstWhere((exercise) => exercise.id == 'interval_perf8_asc_c4_01')
          .options
          .map((option) => option.id),
      ['min2', 'perf4', 'min6', 'perf8'],
    );
    expect(
      musical
          .firstWhere((exercise) => exercise.id == 'interval_perf5_asc_c4_01')
          .options
          .map((option) => option.id),
      ['min2', 'maj3', 'perf5', 'perf8'],
    );
    expect(
      musical
          .firstWhere((exercise) => exercise.id == 'interval_min2_asc_c4_01')
          .options
          .map((option) => option.id),
      ['min2', 'perf4', 'min6', 'perf8'],
    );
    expect(
      musical
          .where(
            (exercise) =>
                exercise.type == 'interval_quality' &&
                exercise.access == 'account',
          )
          .length,
      561,
    );
    expect(
      musical
          .where((exercise) => exercise.type == 'chord_quality')
          .every((exercise) => exercise.access == 'premium'),
      isTrue,
    );
    expect(
      musical
          .where((exercise) => exercise.type == 'interval_quality')
          .map((exercise) => exercise.intro)
          .toSet(),
      {'Escucha las dos notas e identifica el intervalo.'},
    );
    expect(
      musical
          .where((exercise) => exercise.type == 'chord_quality')
          .map((exercise) => exercise.intro)
          .toSet(),
      {'Escucha el acorde y elige la opción que lo describe.'},
    );
    expect(
      eqExercises
          .where((exercise) => exercise.id.startsWith('EQ_0'))
          .map((exercise) => exercise.access)
          .toList(),
      ['free', 'free', 'free', 'account', 'account'],
    );
    expect(
      eqExercises
          .where(
            (exercise) =>
                exercise.id.startsWith('EQ_INIT_') ||
                exercise.type == 'eq_band',
          )
          .every((exercise) => exercise.access == 'free'),
      isTrue,
    );
  });

  test('advanced EQ uses the prepared pink boosts', () async {
    const frequencies = ['125', '250', '500', '1000', '2000', '4000', '8000'];
    const gains = ['6', '9', '-3', '-6'];
    const tokens = {'6': 'g6', '9': 'g9', '-3': 'c3', '-6': 'c6'};
    final band = eqExercises
        .where(
          (exercise) =>
              exercise.type == 'eq_band' && exercise.tags['source'] == 'pink',
        )
        .toList();
    expect(band, hasLength(28));
    expect(EqPractice.of(EqSource.music), isEmpty);
    expect(band.map((exercise) => exercise.tags['source']).toSet(), {'pink'});
    expect(
      band.map((exercise) => exercise.tags['frequency']).toSet(),
      frequencies.toSet(),
    );
    expect(
      band.map((exercise) => exercise.tags['gain']).toSet(),
      gains.toSet(),
    );
    expect(band.map((exercise) => exercise.audio.path).toSet(), hasLength(28));

    for (final exercise in band) {
      expect(exercise.options, hasLength(4));
      expect(exercise.options.map((option) => option.id).toSet(), hasLength(4));
      expect(
        exercise.options.map((option) => option.id),
        contains(exercise.correct),
      );
      final correct = exercise.options.firstWhere(
        (option) => option.id == exercise.correct,
      );
      final gain = int.parse(exercise.tags['gain']!);
      final gainLabel = gain > 0 ? '+$gain dB' : '−${gain.abs()} dB';
      expect(correct.label, '${exercise.tags['frequency']} Hz · $gainLabel');
      expect(exercise.explanation, contains(correct.label));
      expect(
        exercise.referencePath,
        'assets/eq/eq_pink_noise/pink_reference_01.m4a',
      );
      expect(
        exercise.audio.path,
        'assets/eq/eq_pink_noise/freq_pink_${gain > 0 ? 'boost' : 'cut'}_'
        '${exercise.tags['frequency']}_${tokens['${exercise.tags['gain']}']}_01.m4a',
      );
      expect(exercise.audio.path, isNot(contains('eq_band')));
      expect(exercise.audio.path, isNot(contains('music_instrumental_01')));
    }

    final lessons = eqExercises
        .where((exercise) => exercise.id.startsWith('EQ_INIT_'))
        .toList();
    expect(lessons.map((exercise) => exercise.id), [
      'EQ_INIT_HPF',
      'EQ_INIT_LPF',
      'EQ_INIT_LEAN',
    ]);
    expect(lessons.expand((exercise) => exercise.assetPaths).toSet(), {
      'assets/eq/eq_music/filter_hpf_150_music_01.m4a',
      'assets/eq/eq_music/filter_hpf_500_music_01.m4a',
      'assets/eq/eq_music/filter_lpf_4000_music_01.m4a',
    });
    for (final exercise in lessons) {
      final paths = exercise.options.map((option) => option.path).toList();
      expect(paths, hasLength(2));
      expect(paths.toSet(), hasLength(2));
      expect(
        exercise.options
            .firstWhere((option) => option.id == exercise.correct)
            .path,
        exercise.audio.path,
      );
    }

    final first = EqPractice.pick(EqSource.pink, random: Random(3));
    final again = EqPractice.pick(
      EqSource.pink,
      avoidId: first!.id,
      random: Random(3),
    );
    expect(again!.id, isNot(first.id));
    expect(
      await ExerciseRepository.missingAudioWarnings([...band, ...lessons]),
      isEmpty,
    );
  });

  testWidgets('Musical module opens intervals and chords directly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MusicalTrainingScreen()));
    await tester.pump();

    expect(find.text('Intervalos'), findsOneWidget);
    expect(find.text('Acordes'), findsOneWidget);
    expect(find.text('Se desbloquea con premium.'), findsOneWidget);
    expect(find.text('Intervalos ascendentes'), findsNothing);
    expect(find.text('Acordes · tríadas'), findsNothing);
    expect(find.text('3ª mayor'), findsNothing);
    expect(find.text('5ª justa'), findsNothing);
    expect(find.textContaining('ejercicio'), findsNothing);

    expect(find.text('Afinación'), findsOneWidget);

    SharedPreferences.setMockInitialValues({});
    await tester.tap(find.text('ESCUCHAR').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('¿Por qué entrenar intervalos?'), findsOneWidget);
    expect(find.text('2da mayor'), findsNothing);
    await tester.tap(find.text('EMPEZAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // First time: the listening reference, which can be skipped.
    expect(find.text('Referencia: intervalos'), findsOneWidget);
    await tester.tap(find.text('Omitir e ir al ejercicio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Escucha las dos notas e identifica el intervalo.'),
      findsOneWidget,
    );
    expect(find.text('octava'), findsOneWidget);
    expect(find.text('2da mayor'), findsNothing);
    expect(find.text('¿Qué intervalo escuchas?'), findsOneWidget);
    expect(find.text('Pista'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('advanced band exercise records the adjustment', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();

    final exercise = eqExercises.firstWhere(
      (item) => item.id == 'EQ_BAND_PINK_500_P6',
    );
    expect(
      exercise.audio.path,
      'assets/eq/eq_pink_noise/freq_pink_boost_500_g6_01.m4a',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EqBandExerciseScreen.band(
          source: EqSource.pink,
          exercise: exercise,
          level: 1,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('¿Qué frecuencia y ajuste escuchas?'), findsOneWidget);
    // Level 1: the example comes first; the clean pink noise is the second
    // tab and can be heard twice.
    expect(find.text('Ecualizado'), findsOneWidget);
    expect(find.text('Limpio'), findsOneWidget);
    expect(find.text('Ruido rosa ecualizado'), findsOneWidget);
    expect(find.text('Quedan 3 escuchas'), findsOneWidget);
    expect(find.textContaining('Nivel 1 ·'), findsOneWidget);
    await tester.tap(find.text('Limpio'));
    await tester.pump();
    expect(find.text('Quedan 2 escuchas'), findsOneWidget);
    expect(find.text('500 Hz · +6 dB'), findsOneWidget);

    await tester.tap(find.text('500 Hz · +6 dB'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Buen oído.'), findsOneWidget);
    expect(
      find.textContaining('El ajuste correcto es 500 Hz · +6 dB.'),
      findsOneWidget,
    );
    expect(
      MockSession.completedExercises.any(
        (item) => item.id == 'EQ_BAND_PINK_500_P6' && item.correct,
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pink noise level 3 hides the clean reference', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();

    final exercise = eqExercises.firstWhere(
      (item) => item.id == 'EQ_BAND_PINK_500_P6',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EqBandExerciseScreen.band(
          source: EqSource.pink,
          exercise: exercise,
          level: 3,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Limpio'), findsNothing);
    expect(find.text('Escucha el ejemplo'), findsOneWidget);
    expect(find.text('Quedan 3 escuchas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('levels unlock with 5 of the last 6 right, per ladder', () async {
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
    const pink = LevelLadder.pink;
    expect(pink.unlocked, 1);

    for (final correct in [true, false, true, true, true]) {
      expect(await pink.record(level: 1, correct: correct), isNull);
    }
    expect(await pink.record(level: 1, correct: true), 2);
    expect(pink.unlocked, 2);
    // Answers at a lower level never count.
    expect(await pink.record(level: 1, correct: true), isNull);

    for (var i = 0; i < 4; i++) {
      await pink.record(level: 2, correct: true);
    }
    expect(pink.unlocked, 2);
    expect(await pink.record(level: 2, correct: true), 3);
    // The top level unlocks nothing more.
    for (var i = 0; i < 6; i++) {
      expect(await pink.record(level: 3, correct: true), isNull);
    }

    // Each ladder keeps its own level, and it survives a reload.
    expect(LevelLadder.tuning.unlocked, 1);
    await MockSession.load();
    expect(pink.unlocked, 3);
    expect(LevelLadder.tones.unlocked, 1);
  });

  test('Intermedio and Profesional need Premium even when earned', () async {
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
    const pink = LevelLadder.pink;
    for (var i = 0; i < 6; i++) {
      await pink.record(level: 1, correct: true);
    }
    expect(pink.unlocked, 2);

    MockSession.hasPremium = false;
    expect(pink.canPlay(1), isTrue);
    expect(pink.canPlay(2), isFalse);
    expect(pink.playable, 1);
    expect(pink.unlockedNote(2), contains('te espera en Premium'));

    MockSession.hasPremium = true;
    expect(pink.canPlay(2), isTrue);
    expect(pink.canPlay(3), isFalse, reason: 'aún no lo ha ganado');
    expect(pink.playable, 2);

    MockSession.hasPremium = false;
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
  });

  test('no exercise repeats until the rest have come out', () {
    final all = TonePractice.of(ToneDrill.frequency, level: 1);
    final seen = <String>{};
    String? last;
    for (var i = 0; i < all.length; i++) {
      last = TonePractice.pick(
        ToneDrill.frequency,
        level: 1,
        avoidId: last,
      )!.id;
      expect(seen.add(last), isTrue, reason: 'repetido: $last');
    }
    expect(seen, hasLength(all.length));
  });

  test('tuning in context: answers match and audio exists', () async {
    final context = ExerciseRepository.instance
        .byModule('entrenamientoMusical')
        .where((exercise) => exercise.type == 'pitch_context')
        .toList();
    expect(context, hasLength(552));
    final byDrill = <String, int>{};
    for (final exercise in context) {
      final key = 'L${exercise.tags['level']} ${exercise.tags['drill']}';
      byDrill.update(key, (n) => n + 1, ifAbsent: () => 1);
      expect(File(exercise.audio.path).existsSync(), isTrue);
      // The answer is never readable from the file name.
      // ("csharp" is a key, not the answer, so whole words are compared.)
      final words = exercise.audio.path.split('/').last.split(RegExp(r'[_.]'));
      for (final answer in [
        'in',
        'tune',
        'sharp',
        'flat',
        'n1',
        'n2',
        'n3',
        'n4',
        'ok',
        'wrong',
      ]) {
        expect(words, isNot(contains(answer)));
      }
      final cents = int.parse(exercise.tags['cents']!);
      // Básico moves notes by a semitone; Intermedio 50; Profesional less.
      final allowed = switch (exercise.tags['level']) {
        '1' => {0, 100},
        '2' => {0, 50},
        _ => {0, 25, 15, 10},
      };
      expect(allowed, contains(cents.abs()));
      switch (exercise.tags['drill']) {
        case 'melody':
          expect(cents, isNot(0));
          expect(exercise.options.map((option) => option.label), [
            'Nota 1',
            'Nota 2',
            'Nota 3',
            'Nota 4',
          ]);
        case 'chord':
          expect(exercise.correct, cents == 0 ? 'ok' : 'wrong');
        default:
          expect(
            exercise.correct,
            cents == 0 ? 'in_tune' : (cents > 0 ? 'sharp' : 'flat'),
          );
      }
    }
    expect(byDrill, {
      'L1 melody': 48,
      'L1 final': 72,
      'L1 chord': 48,
      'L2 melody': 48,
      'L2 final': 72,
      'L2 third': 72,
      'L3 melody': 48,
      'L3 final': 72,
      'L3 third': 72,
    });
    // The card needs an account; each level draws only its own exercises.
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();
    await MockSession.signIn();
    for (var level = 1; level <= 3; level++) {
      expect(
        MusicalPools.pick(
          MusicalPool.tuningContext,
          level: level,
        )!.tags['level'],
        '$level',
      );
    }
    // Guitar stays out until its notes are re-audited (see
    // MusicalPools.tuningContextExcluded); the piano covers every level.
    final playable = MusicalPools.ofType(MusicalPool.tuningContext);
    expect(playable, hasLength(276));
    expect(playable.map((e) => e.tags['instrument']).toSet(), {'piano'});
  });

  test('intervals: three levels built from the recorded notes', () {
    final intervals = ExerciseRepository.instance
        .byModule('entrenamientoMusical')
        .where((exercise) => exercise.type == 'interval_quality')
        .toList();
    const basic = {'min2', 'maj3', 'perf4', 'perf5', 'perf8'};
    const octave = {
      'min2', 'maj2', 'min3', 'maj3', 'perf4', 'tritone', //
      'perf5', 'min6', 'maj6', 'min7', 'maj7', 'perf8',
    };
    const compound = {'min9', 'maj9', 'min10', 'maj10'};
    Set<String> kinds(String level) => {
      for (final e in intervals)
        if (e.tags['level'] == level) e.correct,
    };
    Set<String> modes(String level) => {
      for (final e in intervals)
        if (e.tags['level'] == level) e.tags['mode']!,
    };
    expect(kinds('1'), basic);
    expect(modes('1'), {'asc', 'desc'});
    expect(kinds('2'), octave);
    expect(kinds('3'), {...octave, ...compound});
    expect(modes('3'), {'asc', 'desc', 'harm'});

    for (final exercise in intervals) {
      expect(File(exercise.audio.path).existsSync(), isTrue);
      expect(
        exercise.options.map((option) => option.id),
        contains(exercise.correct),
      );
      expect({'piano', 'guitar'}, contains(exercise.tags['instrument']));
      if (exercise.tags['level'] != '1') {
        expect(exercise.options, hasLength(4));
      }
    }
    // Both instruments in every level.
    for (final level in ['1', '2', '3']) {
      expect(
        {
          for (final e in intervals)
            if (e.tags['level'] == level) e.tags['instrument'],
        },
        {'piano', 'guitar'},
      );
    }
    // Listening reference: every interval rising, falling and together.
    for (final kind in [...octave, ...compound]) {
      for (final mode in IntervalIntroScreen.modes.keys) {
        expect(File(IntervalIntroScreen.clip(kind, mode)).existsSync(), isTrue);
      }
    }
  });

  test('pink noise reference: every example exists', () {
    expect(File(PinkIntroScreen.reference).existsSync(), isTrue);
    for (final frequency in PinkIntroScreen.frequencies) {
      for (final gain in [9, -6]) {
        final path = PinkIntroScreen.sweep(frequency, gain);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  testWidgets('pink noise reference can be skipped', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await MockSession.load();

    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const PinkIntroScreen()),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Referencia: ruido rosa'), findsOneWidget);
    expect(find.text('Realce +9 dB'), findsNWidgets(7));
    await tester.tap(find.text('Omitir e ir al ejercicio'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(result, isTrue);
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
              {'id': option.id, 'label': option.label, 'path': option.path},
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
