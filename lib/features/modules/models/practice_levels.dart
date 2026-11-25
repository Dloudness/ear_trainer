import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/session/mock_session.dart';
import '../../exercises/models/exercise.dart';

/// A practice split into levels that unlock in order: the next level opens
/// after [MockSession.levelNeeded] right answers among the latest
/// [MockSession.levelWindow] given at the highest unlocked level. Lower
/// levels stay available.
class LevelLadder {
  const LevelLadder({required this.id, required this.names});

  /// Key of the saved progress.
  final String id;

  /// Level names, from level 1 up.
  final List<String> names;

  static const pink = LevelLadder(
    id: 'pink',
    names: ['Nivel 1', 'Nivel 2', 'Nivel 3'],
  );

  static const tuning = LevelLadder(
    id: 'tuning_context',
    names: ['Básico', 'Intermedio', 'Profesional'],
  );

  static const intervals = LevelLadder(
    id: 'intervals',
    names: ['Básico', 'Intermedio', 'Profesional'],
  );

  static const shelves = LevelLadder(
    id: 'eq_shelves',
    names: ['Básico', 'Intermedio', 'Profesional'],
  );

  static const resonances = LevelLadder(
    id: 'eq_resonances',
    names: ['Básico', 'Intermedio', 'Profesional'],
  );

  static const problems = LevelLadder(
    id: 'eq_problems',
    names: ['Básico', 'Intermedio', 'Profesional'],
  );

  static const filters = LevelLadder(
    id: 'eq_filters',
    names: ['Básico', 'Intermedio', 'Profesional'],
  );

  static const tones = LevelLadder(
    id: 'tone_frequency',
    names: ['Octavas', 'Tercios'],
  );

  int get maxLevel => names.length;

  int get unlocked => MockSession.levelOf(id).clamp(1, maxLevel);

  /// Levels above the first need Premium (Básico is free with an account).
  static bool isPremium(int level) => level > 1;

  /// Whether [level] can be practised now: earned and, above the first
  /// level, with Premium.
  bool canPlay(int level) =>
      level <= unlocked && (!isPremium(level) || MockSession.hasPremium);

  /// Highest level that can be practised now.
  int get playable => MockSession.hasPremium ? unlocked : 1;

  String name(int level) => names[level - 1];

  Future<int?> record({required int level, required bool correct}) {
    return MockSession.recordLevelResult(
      ladder: id,
      maxLevel: maxLevel,
      level: level,
      correct: correct,
    );
  }

  /// How to open the next level, shown while [level] is the highest one.
  String? unlockHint(int level) {
    final top = unlocked;
    if (level != top || top >= maxLevel) return null;
    return 'Acierta ${MockSession.levelNeeded} de los últimos '
        '${MockSession.levelWindow} para desbloquear ${name(top + 1)}.';
  }

  /// Shown after the answer that unlocked [level]. Without Premium it is a
  /// congratulation that points to the plans, not a wall.
  String unlockedNote(int level) => MockSession.hasPremium
      ? 'Desbloqueaste ${name(level)}. El siguiente ejercicio ya es de ese nivel.'
      : '¡Lo lograste! El nivel ${name(level)} te espera en Premium.';
}

/// Draws exercises without repeating one until the rest of the list has
/// come out (per [key], for as long as the app is open).
abstract final class NoRepeatPicker {
  static final _seen = <String, Set<String>>{};

  /// Forgets what came out, so the next picks start a fresh round.
  @visibleForTesting
  static void reset() => _seen.clear();

  static Exercise? pick(
    String key,
    List<Exercise> list, {
    String? avoidId,
    Random? random,
  }) {
    if (list.isEmpty) return null;
    final rng = random ?? Random();
    final seen = _seen.putIfAbsent(key, () => <String>{});
    var fresh = [
      for (final exercise in list)
        if (!seen.contains(exercise.id) && exercise.id != avoidId) exercise,
    ];
    if (fresh.isEmpty) {
      seen.clear();
      fresh = [
        for (final exercise in list)
          if (exercise.id != avoidId) exercise,
      ];
      if (fresh.isEmpty) fresh = list;
    }
    final picked = fresh[rng.nextInt(fresh.length)];
    seen.add(picked.id);
    return picked;
  }
}
