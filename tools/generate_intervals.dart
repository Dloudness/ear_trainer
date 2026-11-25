import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'audio_kit.dart';

/// Builds the interval exercises from the owner's recorded notes (piano
/// C3-C6, guitar E2-E5), every note retuned to exactly 0 cents.
///
/// Levels (tags.level):
/// * 1 Básico: 2ª m, 3ª M, 4ª J, 5ª J and 8ª, ascending and descending.
///   Includes the three free lessons (8ª, 5ª, 2ª m ascending from C4).
/// * 2 Intermedio: the 12 intervals of the octave, ascending, descending
///   and harmonic.
/// * 3 Profesional: the 12 plus 9ª m, 9ª M, 10ª m and 10ª M, with the
///   closest (most confusable) intervals as options.
///
/// Each interval, direction and instrument is built on three starting
/// notes that keep both notes inside the instrument's range. Guitar E3-G#3
/// is skipped (fundamental and harmonics disagree in those samples).
/// Files: assets/musical/intervalos/interval_{kind}_{mode}_{note}_{instrument}_01.wav
/// Listening reference (piano): assets/musical/intervalos_referencia/.
/// Every file is set to -25 LUFS, 48 kHz / 16-bit mono.
///
/// Usage: `dart run tools/generate_intervals.dart <recordings dir>`
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Uso: dart run tools/generate_intervals.dart <carpeta de grabaciones>',
    );
    exit(64);
  }
  const outDir = 'audio_masters/musical/intervalos';
  const refDir = 'audio_masters/musical/intervalos_referencia';
  Directory(outDir).createSync(recursive: true);
  Directory(refDir).createSync(recursive: true);
  final rng = math.Random(20261124);
  final piano = Instrument.load(
    'piano',
    'piano',
    '${args[0]}/piano_notas',
    48,
    84,
    bass: 48,
    chord: 57,
    melody: 67,
    strumMs: 0,
  );
  final guitar = Instrument.load(
    'guitar',
    'guitarra',
    '${args[0]}/guitarra_notas',
    40,
    76,
    bass: 40,
    chord: 52,
    melody: 59,
    strumMs: 15,
  );

  final catalogFile = File('assets/data/exercises.json');
  final catalog =
      jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
  final list = (catalog['exercises'] as List).cast<Map<String, dynamic>>();
  // Texts already written for each interval and direction are reused.
  final copy = <String, Map<String, String>>{};
  for (final e in list.where((e) => e['type'] == 'interval_quality')) {
    final key = '${e['correct']}_${(e['tags'] as Map)['mode']}';
    copy.putIfAbsent(
      key,
      () => {'explanation': e['explanation'], 'tip': e['tip'] ?? ''},
    );
  }

  final written = <String>{};
  String render(
    Instrument inst,
    int root,
    int second,
    String mode,
    String path,
  ) {
    if (written.add(path)) {
      final mix = Mix();
      if (mode == 'harm') {
        mix.add(inst.note(root, rng, 0), 0.05, 2.4, 1.0);
        mix.add(
          inst.note(second, rng, 0),
          0.05 + inst.strumMs / 1000,
          2.4,
          1.0,
        );
      } else {
        mix.add(inst.note(root, rng, 0), 0.05, 0.85, 1.0);
        mix.add(inst.note(second, rng, 0), 1.0, 1.8, 1.0);
      }
      mix.write(path);
    }
    return path;
  }

  final exercises = <Map<String, dynamic>>[];
  for (var level = 1; level <= 3; level++) {
    final kinds = _levelKinds[level - 1];
    final modes = level == 1
        ? const ['asc', 'desc']
        : const ['asc', 'desc', 'harm'];
    for (final kind in kinds) {
      for (final mode in modes) {
        for (final inst in [piano, guitar]) {
          for (final root in _roots(inst, kind, mode)) {
            final semis = _semitones[kind]!;
            final second = mode == 'desc' ? root - semis : root + semis;
            final note = noteName(root);
            final path = render(
              inst,
              root,
              second,
              mode,
              '$outDir/interval_${kind}_${mode}_${note}_${inst.id}_01.wav',
            );
            final legacyId = 'interval_${kind}_${mode}_${note}_01';
            final free =
                level == 1 &&
                inst.id == 'piano' &&
                _freeOptions.containsKey(legacyId);
            final text = copy['${kind}_$mode'] ?? _compoundCopy(kind, mode);
            exercises.add({
              'id': free
                  ? legacyId
                  : 'interval_l${level}_${kind}_${mode}_${note}_${inst.id}',
              'module': 'entrenamientoMusical',
              'type': 'interval_quality',
              'audio': {'source': 'asset', 'path': path},
              'intro': 'Escucha las dos notas e identifica el intervalo.',
              'question': '¿Qué intervalo escuchas?',
              'options': [
                for (final option
                    in free
                        ? _freeOptions[legacyId]!
                        : _choices(kind, level, kinds))
                  {'id': option, 'label': _labels[option]!},
              ],
              if (level == 1 && !free) 'maxOptions': 4,
              'correct': kind,
              'difficulty': const [
                'beginner',
                'intermediate',
                'advanced',
              ][level - 1],
              'explanation': text['explanation'],
              if ((text['tip'] ?? '').isNotEmpty) 'tip': text['tip'],
              'tags': {
                'mode': mode,
                'startNote': note,
                'level': '$level',
                'instrument': inst.id,
                'semitones': '$semis',
              },
              'access': free ? 'free' : 'account',
            });
          }
        }
      }
    }
  }

  // Listening reference: every interval on piano, from C4 (descending
  // from C5 so the lower note stays in range).
  for (final kind in _levelKinds.last) {
    final semis = _semitones[kind]!;
    for (final mode in const ['asc', 'desc', 'harm']) {
      final root = mode == 'desc' ? 72 : 60;
      final second = mode == 'desc' ? root - semis : root + semis;
      render(
        piano,
        root,
        second,
        mode,
        '$refDir/interval_ref_${kind}_$mode.wav',
      );
    }
  }

  final removed = list.where((e) => e['type'] == 'interval_quality').length;
  list.removeWhere((e) => e['type'] == 'interval_quality');
  list.addAll(exercises);
  catalogFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );
  final top = peaks.values.reduce(math.max);
  stdout.writeln(
    'Pico máximo: ${(20 * math.log(top) / math.ln10).toStringAsFixed(1)} dBFS',
  );
  stdout.writeln(
    'Retirados: $removed · Conectados: ${exercises.length} · Audios: ${written.length}',
  );
}

const _semitones = {
  'min2': 1,
  'maj2': 2,
  'min3': 3,
  'maj3': 4,
  'perf4': 5,
  'tritone': 6,
  'perf5': 7,
  'min6': 8,
  'maj6': 9,
  'min7': 10,
  'maj7': 11,
  'perf8': 12,
  'min9': 13,
  'maj9': 14,
  'min10': 15,
  'maj10': 16,
};

const _labels = {
  'min2': '2da menor',
  'maj2': '2da mayor',
  'min3': '3ra menor',
  'maj3': '3ra mayor',
  'perf4': '4ta justa',
  'tritone': 'tritono',
  'perf5': '5ta justa',
  'min6': '6ta menor',
  'maj6': '6ta mayor',
  'min7': '7ma menor',
  'maj7': '7ma mayor',
  'perf8': 'octava',
  'min9': '9na menor',
  'maj9': '9na mayor',
  'min10': '10ma menor',
  'maj10': '10ma mayor',
};

const _levelKinds = [
  ['min2', 'maj3', 'perf4', 'perf5', 'perf8'],
  [
    'min2', 'maj2', 'min3', 'maj3', 'perf4', 'tritone', //
    'perf5', 'min6', 'maj6', 'min7', 'maj7', 'perf8',
  ],
  [
    'min2', 'maj2', 'min3', 'maj3', 'perf4', 'tritone', 'perf5', 'min6', //
    'maj6', 'min7', 'maj7', 'perf8', 'min9', 'maj9', 'min10', 'maj10',
  ],
];

/// The three free lessons keep their fixed, clearly different choices.
const _freeOptions = {
  'interval_perf8_asc_c4_01': ['min2', 'perf4', 'min6', 'perf8'],
  'interval_perf5_asc_c4_01': ['min2', 'maj3', 'perf5', 'perf8'],
  'interval_min2_asc_c4_01': ['min2', 'perf4', 'min6', 'perf8'],
};

/// Level 1: all five (the app shows four). Levels 2-3: the answer and the
/// three closest intervals of the level, from small to large.
List<String> _choices(String kind, int level, List<String> kinds) {
  if (level == 1) return kinds;
  final s = _semitones[kind]!;
  final others = [...kinds]..remove(kind);
  others.sort((a, b) {
    final da = (_semitones[a]! - s).abs(), db = (_semitones[b]! - s).abs();
    return da != db
        ? da.compareTo(db)
        : _semitones[a]!.compareTo(_semitones[b]!);
  });
  return [kind, ...others.take(3)]
    ..sort((a, b) => _semitones[a]!.compareTo(_semitones[b]!));
}

/// Up to three starting notes per instrument that keep both notes in range
/// (and, on guitar, away from the E3-G#3 samples).
List<int> _roots(Instrument inst, String kind, String mode) {
  const pianoRoots = [60, 57, 64, 62, 65, 67, 55, 53, 50, 69];
  const guitarRoots = [57, 60, 50, 59, 62, 47, 45, 64, 48, 43];
  bool ok(int m) =>
      m >= inst.low &&
      m <= inst.high &&
      !(inst.id == 'guitar' && m >= 52 && m <= 56);
  final s = _semitones[kind]!;
  return [
    for (final root in inst.id == 'piano' ? pianoRoots : guitarRoots)
      if (ok(root) && ok(mode == 'desc' ? root - s : root + s)) root,
  ].take(3).toList();
}

Map<String, String> _compoundCopy(String kind, String mode) {
  final (name, simple) = switch (kind) {
    'min9' => ('una novena menor', 'una segunda menor'),
    'maj9' => ('una novena mayor', 'una segunda mayor'),
    'min10' => ('una décima menor', 'una tercera menor'),
    _ => ('una décima mayor', 'una tercera mayor'),
  };
  final where = switch (mode) {
    'asc' => 'La segunda nota está más aguda.',
    'desc' => 'La segunda nota está más grave.',
    _ => 'Las dos notas suenan a la vez.',
  };
  return {
    'explanation':
        'Es $name: una octava más $simple (${_semitones[kind]} semitonos). $where',
    'tip':
        'Imagina primero la octava y luego cuánto la sobrepasa: suena como $simple, pero más abierta.',
  };
}
