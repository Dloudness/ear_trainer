import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../models/exercise.dart';

class MissingAudioReport {
  const MissingAudioReport({
    required this.warnings,
    required this.exerciseIds,
  });

  final List<String> warnings;
  final Set<String> exerciseIds;
}

class ExerciseParseResult {
  const ExerciseParseResult({
    required this.exercises,
    required this.warnings,
  });

  final List<Exercise> exercises;
  final List<String> warnings;
}

class ExerciseRepository {
  ExerciseRepository._();

  static final ExerciseRepository instance = ExerciseRepository._();

  static const assetPath = 'assets/data/exercises.json';

  final List<Exercise> _exercises = [];
  final Set<String> _missingAudioIds = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final parsed = parse(raw);
    final missing = await inspectAudio(parsed.exercises);
    _exercises
      ..clear()
      ..addAll(parsed.exercises);
    _missingAudioIds
      ..clear()
      ..addAll(missing.exerciseIds);
    _loaded = true;
    for (final warning in [...parsed.warnings, ...missing.warnings]) {
      debugPrint(warning);
    }
  }

  bool isPlayable(Exercise exercise) {
    _ensureLoaded();
    return !_missingAudioIds.contains(exercise.id);
  }

  List<Exercise> byModule(String module) {
    _ensureLoaded();
    return [
      for (final exercise in _exercises)
        if (exercise.module == module) exercise,
    ];
  }

  static ExerciseParseResult parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['exercises'] is! List) {
      throw const FormatException(
        'exercises.json debe contener la lista "exercises".',
      );
    }

    final exercises = <Exercise>[];
    final warnings = <String>[];
    final seenIds = <String>{};
    final list = decoded['exercises'] as List;
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) {
        throw FormatException('La entrada $i de exercises no es un objeto.');
      }
      final exercise = Exercise.fromJson(Map<String, dynamic>.from(item));
      if (!seenIds.add(exercise.id)) {
        warnings.add(
          'ExerciseRepository: id duplicado "${exercise.id}". '
          'Se conserva la primera entrada.',
        );
        continue;
      }
      exercises.add(exercise);
    }

    return ExerciseParseResult(
      exercises: List<Exercise>.unmodifiable(exercises),
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  static Future<List<String>> missingAudioWarnings(
    List<Exercise> exercises,
  ) async {
    return (await inspectAudio(exercises)).warnings;
  }

  static Future<MissingAudioReport> inspectAudio(
    List<Exercise> exercises,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest.listAssets().toSet();
    final warnings = <String>[];
    final exerciseIds = <String>{};
    for (final exercise in exercises) {
      final checked = <String>{};
      for (final path in exercise.assetPaths) {
        final key = AppAssets.bundle(path);
        if (!checked.add(key) || available.contains(key)) continue;
        exerciseIds.add(exercise.id);
        warnings.add(
          'ExerciseRepository: audio inexistente en ${exercise.id}: $key',
        );
      }
    }
    return MissingAudioReport(
      warnings: List<String>.unmodifiable(warnings),
      exerciseIds: Set<String>.unmodifiable(exerciseIds),
    );
  }

  void _ensureLoaded() {
    if (_loaded) return;
    throw StateError('ExerciseRepository.load() no se ha llamado.');
  }
}
