import 'package:ear_trainer/core/storage/progress_repository.dart';
import 'package:ear_trainer/features/home/models/mentor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 24, 18);

  List<CompletedExerciseRecord> answers(String prefix, int right, int wrong) {
    var i = 0;
    CompletedExerciseRecord one(bool correct) => CompletedExerciseRecord(
      id: '$prefix${i++}',
      correct: correct,
      attempts: 1,
      completedAt: now.subtract(Duration(minutes: i)),
    );
    return [
      for (var n = 0; n < right; n++) one(true),
      for (var n = 0; n < wrong; n++) one(false),
    ];
  }

  test('with no answers it suggests starting with equalization', () {
    final advice = MentorAdvice.build(records: const [], now: now);
    expect(advice.focus, SkillArea.equalization);
    expect(advice.headline, 'Empecemos por la base');
    expect(advice.praise, isEmpty);
    expect(
      advice.reports.map((r) => r.status).toSet(),
      {'Sin empezar'},
    );
  });

  test('it recommends reinforcing the weakest area', () {
    final advice = MentorAdvice.build(
      records: [
        ...answers('EQ_', 9, 1),
        ...answers('PCTX_', 2, 4),
      ],
      now: now,
    );
    expect(advice.focus, SkillArea.tuning);
    expect(advice.headline, 'Te conviene reforzar Afinación');
    expect(advice.message, contains('2 de tus últimas 6'));
    final eq = advice.reports.firstWhere(
      (r) => r.area == SkillArea.equalization,
    );
    expect(eq.status, 'Sólido');
    expect(eq.outOfTen, 9);
    expect(
      advice.praise,
      contains('Muy bien en Frecuencias: aciertas 9 de cada 10.'),
    );
  });

  test('when everything goes well it suggests an untried area', () {
    final advice = MentorAdvice.build(
      records: answers('EQ_', 5, 0),
      now: now,
    );
    expect(advice.headline, 'Vas por buen camino');
    expect(advice.focus, isNot(SkillArea.equalization));
  });

  test('it never suggests a Premium area the listener cannot open', () {
    // Everything tried and going well except Acordes (Premium, locked).
    final advice = MentorAdvice.build(
      records: [
        ...answers('EQ_', 5, 0),
        ...answers('TONE_', 5, 0),
        ...answers('interval_', 5, 0),
        ...answers('PCTX_', 5, 0),
      ],
      now: now,
    );
    expect(SkillArea.chords.locked, isTrue);
    expect(SkillArea.soundDesign.locked, isTrue);
    expect(advice.focus, isNot(SkillArea.chords));
    expect(advice.focus, isNot(SkillArea.soundDesign));
    expect(advice.headline, 'Vas muy bien');
  });

  test('only the latest ten answers count', () {
    // 10 old mistakes, then 10 recent right answers.
    final old = [
      for (var i = 0; i < 10; i++)
        CompletedExerciseRecord(
          id: 'interval_old$i',
          correct: false,
          attempts: 1,
          completedAt: now.subtract(Duration(days: 10, minutes: i)),
        ),
    ];
    final advice = MentorAdvice.build(
      records: [...old, ...answers('interval_', 10, 0)],
      now: now,
    );
    final intervals = advice.reports.firstWhere(
      (r) => r.area == SkillArea.intervals,
    );
    expect(intervals.answered, 10);
    expect(intervals.correct, 10);
  });
}
