import '../../../core/router/app_routes.dart';
import '../../../core/session/mock_session.dart';
import '../../../core/storage/progress_repository.dart';
import '../../../core/widgets/category_icon.dart';
import '../../modules/models/practice_levels.dart';
import 'package:flutter/material.dart';

/// A skill the listener trains, grouped from exercise ids.
enum SkillArea {
  /// Equalization, pink noise and pure tones together.
  equalization(
    'Frecuencias',
    ['EQ_', 'TONE_'],
    AppRoutes.moduleFrecuencias,
    CategoryGlyph.frequency,
    [Color(0xFFA5F3FC), Color(0xFF3B82F6)],
    LevelLadder.pink,
  ),
  intervals(
    'Intervalos',
    ['interval_'],
    AppRoutes.moduleMusical,
    CategoryGlyph.musical,
    [Color(0xFFE9D5FF), Color(0xFF7C3AED)],
    LevelLadder.intervals,
  ),
  chords(
    'Acordes',
    ['chord_'],
    AppRoutes.moduleMusical,
    CategoryGlyph.musical,
    [Color(0xFFDDD6FE), Color(0xFF6D28D9)],
    null,
    premium: true,
  ),
  tuning(
    'Afinación',
    ['PITCH_', 'PCTX_'],
    AppRoutes.moduleMusical,
    CategoryGlyph.musical,
    [Color(0xFFFBCFE8), Color(0xFFDB2777)],
    LevelLadder.tuning,
  ),

  /// Sound for film, video and podcast. Premium.
  soundDesign(
    'Diseño sonoro',
    ['SD_'],
    AppRoutes.moduleDisenoSonoro,
    CategoryGlyph.video,
    [Color(0xFFFED7AA), Color(0xFFEA580C)],
    null,
    premium: true,
  );

  const SkillArea(
    this.title,
    this.prefixes,
    this.route,
    this.glyph,
    this.colors,
    this.ladder, {
    this.premium = false,
  });

  /// Needs a Premium subscription.
  final bool premium;

  /// Premium area the listener cannot open yet.
  bool get locked => premium && !MockSession.hasPremium;

  final String title;
  final List<String> prefixes;
  final String route;
  final CategoryGlyph glyph;
  final List<Color> colors;
  final LevelLadder? ladder;

  static SkillArea? of(String exerciseId) {
    for (final area in values) {
      if (area.prefixes.any(exerciseId.startsWith)) return area;
    }
    return null;
  }
}

/// How the listener is doing in one area. Only the latest answers count,
/// so the picture follows their progress instead of their first tries.
class SkillReport {
  const SkillReport(this.area, this.answered, this.correct);

  /// Latest answers taken into account.
  static const window = 10;

  /// Below this many answers there is not enough to judge.
  static const minimum = 4;

  final SkillArea area;
  final int answered;
  final int correct;

  bool get started => answered > 0;
  bool get enough => answered >= minimum;

  /// Right answers out of ten (rounded), e.g. 7 → "7 de cada 10".
  int get outOfTen => answered == 0 ? 0 : (correct * 10 / answered).round();
  double get ratio => answered == 0 ? 0 : correct / answered;

  String get status {
    if (!started) return 'Sin empezar';
    if (!enough) return 'Empezando';
    if (ratio >= 0.85) return 'Sólido';
    if (ratio >= 0.65) return 'En progreso';
    return 'Por reforzar';
  }

  /// Level name reached, when the area has levels and it is above the first.
  String? get levelReached {
    final ladder = area.ladder;
    if (ladder == null || ladder.unlocked <= 1) return null;
    return ladder.name(ladder.unlocked);
  }
}

/// What the advisor says on the home screen.
class MentorAdvice {
  const MentorAdvice({
    required this.headline,
    required this.message,
    required this.focus,
    required this.action,
    required this.reports,
    required this.praise,
    required this.tip,
    required this.daysThisWeek,
  });

  final String headline;
  final String message;

  /// Area to practice next.
  final SkillArea focus;

  /// Label of the main button.
  final String action;
  final List<SkillReport> reports;

  /// Congratulations, most recent first. May be empty.
  final List<String> praise;
  final String tip;

  /// Different days with practice in the last seven.
  final int daysThisWeek;

  static MentorAdvice build({
    List<CompletedExerciseRecord>? records,
    DateTime? now,
  }) {
    final all = records ?? MockSession.records;
    final today = now ?? DateTime.now();

    final byArea = {for (final area in SkillArea.values) area: <CompletedExerciseRecord>[]};
    for (final record in all) {
      final area = SkillArea.of(record.id);
      if (area != null) byArea[area]!.add(record);
    }
    final reports = [
      for (final area in SkillArea.values)
        () {
          final latest = [...byArea[area]!]
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
          final window = latest.take(SkillReport.window).toList();
          return SkillReport(
            area,
            window.length,
            window.where((r) => r.correct).length,
          );
        }(),
    ];

    final weekAgo = today.subtract(const Duration(days: 7));
    final days = {
      for (final r in all)
        if (r.completedAt.isAfter(weekAgo))
          '${r.completedAt.year}-${r.completedAt.month}-${r.completedAt.day}',
    }.length;

    final praise = <String>[
      for (final report in reports)
        if (report.levelReached case final level?)
          'Llegaste al nivel $level en ${report.area.title}.',
      for (final report in reports)
        if (report.enough && report.ratio >= 0.8)
          'Muy bien en ${report.area.title}: aciertas ${report.outOfTen} de cada 10.',
      if (days >= 4) 'Practicaste $days días esta semana. Esa constancia es lo que entrena el oído.',
    ];

    final judged = [
      for (final report in reports)
        if (report.enough) report,
    ]..sort((a, b) => a.ratio.compareTo(b.ratio));
    // Never suggest an area the listener cannot open yet.
    final untried = [
      for (final report in reports)
        if (!report.started && !report.area.locked) report,
    ];

    final String headline;
    final String message;
    final SkillArea focus;
    if (all.isEmpty || reports.every((r) => !r.started)) {
      focus = SkillArea.equalization;
      headline = 'Empecemos por la base';
      message =
          'Te recomiendo empezar por Frecuencias: aprender a ubicar graves, '
          'medios y agudos es la base para todo lo demás.';
    } else if (judged.isNotEmpty && judged.first.ratio < 0.65) {
      final weak = judged.first;
      focus = weak.area;
      headline = 'Te conviene reforzar ${weak.area.title}';
      message =
          'Acertaste ${weak.correct} de tus últimas ${weak.answered} respuestas. '
          'Es normal en esta etapa: unos minutos al día marcan la diferencia.';
    } else if (untried.isNotEmpty) {
      focus = untried.first.area;
      headline = 'Vas por buen camino';
      message =
          '¿Qué tal si hoy pruebas ${focus.title}? Entrenar el oído en otra '
          'dirección también fortalece lo que ya sabes.';
    } else if (judged.isNotEmpty) {
      final next = judged.first;
      focus = next.area;
      headline = 'Vas muy bien';
      message =
          'Tus resultados son buenos en todas las áreas. Para seguir creciendo, '
          'apunta al siguiente nivel en ${focus.title}.';
    } else {
      // Every area started but none with enough answers yet.
      final least = [
        for (final report in reports)
          if (!report.area.locked) report,
      ]..sort((a, b) => a.answered.compareTo(b.answered));
      focus = least.first.area;
      headline = 'Sigue explorando';
      message =
          'Aún estoy conociendo tu oído. Haz unos ejercicios más de '
          '${focus.title} y te diré en qué conviene enfocarte.';
    }

    return MentorAdvice(
      headline: headline,
      message: message,
      focus: focus,
      action: 'Practicar ${focus.title}',
      reports: reports,
      praise: praise,
      tip: _tipFor(focus, today),
      daysThisWeek: days,
    );
  }

  static String _tipFor(SkillArea area, DateTime day) {
    final tips = switch (area) {
      SkillArea.equalization => const [
        'Antes de buscar la frecuencia, pregúntate si el sonido ganó o perdió algo: cuerpo, claridad o brillo.',
        'Escucha a un volumen moderado: con el volumen alto, los graves y los agudos parecen más fuertes de lo que son.',
        'Asocia cada zona a una palabra: 125 Hz peso, 500 Hz caja, 2 kHz presencia, 8 kHz aire.',
        'Con los tonos puros, canta mentalmente el tono antes de responder: ubicarlo en tu voz ayuda a recordar la altura.',
        'Usa audífonos: en los parlantes del celular los graves casi no se escuchan.',
      ],
      SkillArea.intervals => const [
        'Asocia cada intervalo al comienzo de una canción que conozcas.',
        'Fíjate primero en si la segunda nota sube o baja, y después en la distancia.',
        'Cantar los intervalos en voz baja es de lo que más ayuda a fijarlos.',
      ],
      SkillArea.chords => const [
        'Mayor suele sentirse luminoso y menor, más oscuro: empieza por esa sensación.',
        'Intenta cantar la nota más grave del acorde: te da la referencia del resto.',
      ],
      SkillArea.tuning => const [
        'Escucha el "batido": cuando dos notas casi coinciden, el sonido ondula. Afinadas, se funden.',
        'Concéntrate en la nota final: después de una cadencia, el oído espera la tónica.',
        'Las desafinaciones pequeñas se notan más en notas largas que en notas rápidas.',
      ],
      SkillArea.soundDesign => const [
        'En una escena, el ambiente cuenta dónde estamos antes que la imagen.',
        'Un diálogo claro vale más que una música espectacular: la voz manda.',
      ],
    };
    final dayOfYear = day.difference(DateTime(day.year)).inDays;
    return tips[dayOfYear % tips.length];
  }
}
