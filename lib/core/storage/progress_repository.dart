import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CompletedExerciseRecord {
  const CompletedExerciseRecord({
    required this.id,
    required this.correct,
    required this.attempts,
    required this.completedAt,
  });

  final String id;
  final bool correct;
  final int attempts;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'correct': correct,
        'attempts': attempts,
        'completedAt': completedAt.toIso8601String(),
      };

  factory CompletedExerciseRecord.fromJson(Map<String, dynamic> json) {
    return CompletedExerciseRecord(
      id: json['id'] as String,
      correct: json['correct'] as bool? ?? false,
      attempts: json['attempts'] as int? ?? 1,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  CompletedExerciseRecord copyWith({
    bool? correct,
    int? attempts,
    DateTime? completedAt,
  }) {
    return CompletedExerciseRecord(
      id: id,
      correct: correct ?? this.correct,
      attempts: attempts ?? this.attempts,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class ProgressSnapshot {
  const ProgressSnapshot({
    this.exercises = const [],
    this.xp = 0,
    this.streakDays = 0,
    this.lastActivityDate,
    this.hasCompletedDemo = false,
    this.trainingFocus,
  });

  final List<CompletedExerciseRecord> exercises;
  final int xp;
  final int streakDays;
  final String? lastActivityDate;
  final bool hasCompletedDemo;
  final String? trainingFocus;

  ProgressSnapshot copyWith({
    List<CompletedExerciseRecord>? exercises,
    int? xp,
    int? streakDays,
    String? lastActivityDate,
    bool? hasCompletedDemo,
    String? trainingFocus,
  }) {
    return ProgressSnapshot(
      exercises: exercises ?? this.exercises,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      hasCompletedDemo: hasCompletedDemo ?? this.hasCompletedDemo,
      trainingFocus: trainingFocus ?? this.trainingFocus,
    );
  }
}

/// Local persistence for exercise results, XP and daily streak.
class ProgressRepository {
  ProgressRepository();

  static const _kExercises = 'progress.exercises';
  static const _kXp = 'progress.xp';
  static const _kStreak = 'progress.streakDays';
  static const _kLastActivity = 'progress.lastActivityDate';
  static const _kHasCompletedDemo = 'progress.hasCompletedDemo';
  static const _kTrainingFocus = 'progress.trainingFocus';

  Future<ProgressSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kExercises) ?? const [];
    final exercises = raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return CompletedExerciseRecord.fromJson(decoded);
            }
            if (decoded is Map) {
              return CompletedExerciseRecord.fromJson(
                decoded.cast<String, dynamic>(),
              );
            }
          } catch (_) {}
          return null;
        })
        .whereType<CompletedExerciseRecord>()
        .toList();

    return ProgressSnapshot(
      exercises: exercises,
      xp: prefs.getInt(_kXp) ?? 0,
      streakDays: prefs.getInt(_kStreak) ?? 0,
      lastActivityDate: prefs.getString(_kLastActivity),
      hasCompletedDemo: prefs.getBool(_kHasCompletedDemo) ?? false,
      trainingFocus: prefs.getString(_kTrainingFocus),
    );
  }

  Future<void> save(ProgressSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kExercises,
      snapshot.exercises.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await prefs.setInt(_kXp, snapshot.xp);
    await prefs.setInt(_kStreak, snapshot.streakDays);
    if (snapshot.lastActivityDate == null) {
      await prefs.remove(_kLastActivity);
    } else {
      await prefs.setString(_kLastActivity, snapshot.lastActivityDate!);
    }
    await prefs.setBool(_kHasCompletedDemo, snapshot.hasCompletedDemo);
    if (snapshot.trainingFocus == null) {
      await prefs.remove(_kTrainingFocus);
    } else {
      await prefs.setString(_kTrainingFocus, snapshot.trainingFocus!);
    }
  }
}
