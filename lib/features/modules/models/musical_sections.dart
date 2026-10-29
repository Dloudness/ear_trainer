import 'package:flutter/material.dart';

import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import '../../onboarding/models/onboarding_option.dart';

enum MusicalSectionId {
  intervalsAscending,
  intervalsDescending,
  intervalsHarmonic,
  triads,
  sevenths,
  inversions,
}

class MusicalSection {
  const MusicalSection({
    required this.id,
    required this.title,
    required this.exercises,
  });

  final MusicalSectionId id;
  final String title;
  final List<Exercise> exercises;
}

abstract final class MusicalSections {
  static const moduleName = 'entrenamientoMusical';
  static const accent = Color(0xFF818CF8);
  static final _reportedSkips = <String>{};

  static const _order = <MusicalSectionId, String>{
    MusicalSectionId.intervalsAscending: 'Intervalos ascendentes',
    MusicalSectionId.intervalsDescending: 'Intervalos descendentes',
    MusicalSectionId.intervalsHarmonic: 'Intervalos armónicos',
    MusicalSectionId.triads: 'Acordes · tríadas',
    MusicalSectionId.sevenths: 'Acordes · séptimas',
    MusicalSectionId.inversions: 'Acordes · inversiones',
  };

  static const _difficultyRank = {
    'beginner': 0,
    'intermediate': 1,
    'advanced': 2,
  };

  static List<MusicalSection> all() {
    final grouped = {
      for (final id in _order.keys) id: <Exercise>[],
    };
    final module = OnboardingOption.entrenamientoMusical.name;
    for (final exercise in ExerciseRepository.instance.byModule(module)) {
      if (!ExerciseRepository.instance.isPlayable(exercise)) {
        _reportSkip(
          exercise.id,
          'porque su audio no está en el bundle',
        );
        continue;
      }
      final sectionId = _sectionFor(exercise);
      if (sectionId == null) {
        _reportSkip(exercise.id, 'porque no entra en ninguna sección');
        continue;
      }
      grouped[sectionId]!.add(exercise);
    }

    return [
      for (final entry in _order.entries)
        if (grouped[entry.key]!.isNotEmpty)
          MusicalSection(
            id: entry.key,
            title: entry.value,
            exercises: _sorted(grouped[entry.key]!),
          ),
    ];
  }

  static MusicalSection? byId(MusicalSectionId id) {
    for (final section in all()) {
      if (section.id == id) return section;
    }
    return null;
  }

  static List<Exercise> playableExercises() {
    return [
      for (final section in all()) ...section.exercises,
    ];
  }

  static void _reportSkip(String id, String reason) {
    if (!_reportedSkips.add(id)) return;
    debugPrint('MusicalSections: se omite $id $reason.');
  }

  static MusicalSectionId? _sectionFor(Exercise exercise) {
    if (exercise.module != moduleName &&
        exercise.module != OnboardingOption.entrenamientoMusical.name) {
      return null;
    }
    if (exercise.type == 'interval_quality') {
      return switch (exercise.tags['mode']) {
        'asc' => MusicalSectionId.intervalsAscending,
        'desc' => MusicalSectionId.intervalsDescending,
        'harm' => MusicalSectionId.intervalsHarmonic,
        _ => null,
      };
    }
    if (exercise.type != 'chord_quality') return null;
    final inversion = exercise.tags['inversion'] ?? 'root';
    if (inversion != 'root') return MusicalSectionId.inversions;
    return switch (exercise.correct) {
      'maj' || 'min' => MusicalSectionId.triads,
      'maj7' || 'dom7' || 'min7' => MusicalSectionId.sevenths,
      _ => null,
    };
  }

  static List<Exercise> _sorted(List<Exercise> exercises) {
    final copy = [...exercises];
    copy.sort((a, b) {
      final rank = (_difficultyRank[a.difficulty] ?? 9)
          .compareTo(_difficultyRank[b.difficulty] ?? 9);
      if (rank != 0) return rank;
      return a.id.compareTo(b.id);
    });
    return List<Exercise>.unmodifiable(copy);
  }
}
