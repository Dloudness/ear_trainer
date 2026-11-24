import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Builds the "afinación en contexto" exercises from the owner's recorded
/// notes (piano C3-C6, guitar E2-E5), as planned in
/// docs/Ear_Trainer_guia_de_grabacion_afinacion.docx:
///
/// * melody (A2): four-note melody over the tonic chord; ONE note is out
///   of the key or detuned. Answer: which note (1-4).
/// * final (A3): I-IV-V-I cadence with a melody on top; the final melody
///   note is right, sharp or flat.
/// * third (A5): major or minor triad; its third is in tune, sharp or flat.
/// * chord (Básico only): a chord that sounds right or has a wrong note.
///
/// Three levels: Básico (a semitone, out of the key: another recorded
/// note), Intermedio (50 cents) and Profesional (25, 15 and 10 cents).
/// Every note is first retuned to exactly 0 cents (from the measured
/// pitch in the analysis CSVs), then only the target note is shifted by
/// the exact amount with band-limited resampling.
/// Each file is set to -25 LUFS (the same for all, so loudness never gives
/// the answer away; -20 would clip the piano attacks) and written as
/// 48 kHz / 16-bit mono WAV, with no other processing.
/// The answer lives in the JSON ("correct"), never in the file name.
///
/// Usage:
///   `dart run tools/generate_pitch_context.dart <recordings dir>`
/// where `<recordings dir>` holds piano_notas\ and guitarra_notas\ (cortes\
/// plus analisis_*_notas.csv).
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Uso: dart run tools/generate_pitch_context.dart <carpeta de grabaciones>',
    );
    exit(64);
  }
  const outDir = 'assets/pitch_context';
  Directory(outDir).createSync(recursive: true);
  final rng = math.Random(20261124);
  final instruments = [
    _Instrument.load(
      'piano',
      'piano',
      '${args[0]}/piano_notas',
      48,
      84,
      bass: 48,
      chord: 57,
      melody: 67,
      strumMs: 0,
    ),
    _Instrument.load(
      'guitar',
      'guitarra',
      '${args[0]}/guitarra_notas',
      40,
      76,
      bass: 40,
      chord: 52,
      melody: 59,
      strumMs: 15,
    ),
  ];

  final exercises = <Map<String, dynamic>>[];
  // Level 1 (Básico): a note out of the key, a semitone away (100 cents).
  // Level 2 (Intermedio): 50 cents. Level 3 (Profesional): 25, 15, 10.
  int centsFor(int level, int i) => switch (level) {
    1 => 100,
    2 => 50,
    _ => const [25, 15, 10][i % 3],
  };

  for (var level = 1; level <= 3; level++) {
    for (var i = 0; i < instruments.length; i++) {
      final inst = instruments[i];
      for (var key = 0; key < 12; key++) {
        final s = _Spec(inst, level, key, rng, outDir);
        // A2 · melody: two per key.
        for (var v = 0; v < 2; v++) {
          final cents = centsFor(level, key * 2 + v + i);
          final sharp = (key + v) % 2 == 0;
          exercises.add(_melody(s, v + 1, sharp ? cents : -cents));
        }
        // A3 · final note: in tune, sharp and flat per key.
        final offsets = [
          0,
          centsFor(level, key + i),
          -centsFor(level, key + i + 1),
        ];
        for (var v = 0; v < 3; v++) {
          exercises.add(_final(s, v + 1, offsets[v]));
        }
        if (level == 1) {
          // Básico chord: in tune, or with one clearly wrong note.
          for (var v = 0; v < 2; v++) {
            final minor = (key + i) % 2 == 1;
            exercises.add(_wrongNote(s, v + 1, wrong: v == 1, minor: minor));
          }
        } else {
          // A5 · third: in tune, sharp and flat per key.
          for (var v = 0; v < 3; v++) {
            final minor = (key + v) % 2 == 1;
            exercises.add(_third(s, v + 1, offsets[v], minor));
          }
        }
      }
    }
  }

  final catalogFile = File('assets/data/exercises.json');
  final catalog =
      jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
  final list = (catalog['exercises'] as List).cast<Map<String, dynamic>>();
  final removed = list
      .where((e) => (e['id'] as String).startsWith('PCTX_'))
      .length;
  list.removeWhere((e) => (e['id'] as String).startsWith('PCTX_'));
  list.addAll(exercises);
  catalogFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );
  final top = peaks.values.reduce(math.max);
  stdout.writeln(
    'Pico máximo: ${(20 * math.log(top) / math.ln10).toStringAsFixed(1)} dBFS',
  );
  stdout.writeln(
    'Retirados: $removed · Conectados: ${exercises.length} en $outDir',
  );
}

// ---------------------------------------------------------------- exercises

const _scale = [0, 2, 4, 5, 7, 9, 11];
const _keyNames = [
  'Do',
  'Do♯',
  'Re',
  'Re♯',
  'Mi',
  'Fa',
  'Fa♯',
  'Sol',
  'Sol♯',
  'La',
  'La♯',
  'Si',
];
const _keyTokens = [
  'c',
  'csharp',
  'd',
  'dsharp',
  'e',
  'f',
  'fsharp',
  'g',
  'gsharp',
  'a',
  'asharp',
  'b',
];

/// Melodies as scale degrees (0 = tonic, 7 = tonic an octave up).
const _melodies = [
  [0, 1, 2, 0],
  [2, 3, 4, 2],
  [4, 3, 2, 0],
  [0, 2, 4, 2],
  [2, 4, 7, 4],
  [4, 2, 1, 0],
  [1, 2, 3, 2],
  [0, 4, 2, 0],
  [7, 6, 4, 2],
  [2, 1, 0, 4],
];

int _degree(int tonicMidi, int degree) =>
    tonicMidi + 12 * (degree ~/ 7) + _scale[degree % 7];

/// Lowest midi of pitch class [pc] at or above [low].
int _at(int pc, int low) => low + ((pc - low) % 12 + 12) % 12;

const _difficulties = ['beginner', 'intermediate', 'advanced'];

/// What every exercise of one level, instrument and key shares.
class _Spec {
  _Spec(this.inst, this.level, this.key, this.rng, this.dir);

  final _Instrument inst;
  final int level, key;
  final math.Random rng;
  final String dir;

  bool get basic => level == 1;
  String get keyName => '${_keyNames[key]} mayor';

  String file(String drill, int n) =>
      '$dir/pitch_ctx_l${level}_${drill}_${inst.id}_${_keyTokens[key]}_${n.toString().padLeft(2, '0')}.wav';

  String id(String drill, int n) =>
      'PCTX_L${level}_${drill.toUpperCase()}_${inst.id.toUpperCase()}_${_keyTokens[key].toUpperCase()}_0$n';
}

String _direction(int cents) =>
    cents > 0 ? 'alta (más aguda)' : 'baja (más grave)';

Map<String, dynamic> _entry(
  _Spec s, {
  required String drill,
  required int n,
  required int cents,
  required String intro,
  required String question,
  required List<Map<String, String>> options,
  required String correct,
  required String explanation,
  Map<String, String> extraTags = const {},
}) => {
  'id': s.id(drill, n),
  'module': 'entrenamientoMusical',
  'type': 'pitch_context',
  'audio': {'source': 'asset', 'path': s.file(drill, n)},
  'intro': intro,
  'question': question,
  'options': options,
  'correct': correct,
  'difficulty': _difficulties[s.level - 1],
  'explanation': explanation,
  'tags': {
    'skill': 'tuning_context',
    'level': '${s.level}',
    'drill': drill,
    'instrument': s.inst.id,
    'key': _keyTokens[s.key],
    'cents': '$cents',
    ...extraTags,
  },
  'access': 'account',
};

List<Map<String, String>> _tuneOptions(bool basic) => [
  {'id': 'in_tune', 'label': basic ? 'Correcta' : 'Afinada'},
  {'id': 'sharp', 'label': basic ? 'Más alta' : 'Alta'},
  {'id': 'flat', 'label': basic ? 'Más baja' : 'Baja'},
];

String _tuneAnswer(int cents) =>
    cents == 0 ? 'in_tune' : (cents > 0 ? 'sharp' : 'flat');

/// Tonic chord (bass + close triad).
List<int> _triad(_Instrument inst, int rootPc, {bool minor = false}) => [
  _at(rootPc, inst.bass),
  _at(rootPc, inst.chord),
  _at(rootPc + (minor ? 3 : 4), inst.chord),
  _at(rootPc + 7, inst.chord),
];

bool _inScale(int midi, int key) => _scale.contains((midi - key) % 12);

String _pitchName(int midi) => _keyNames[midi % 12];

/// A2 · four-note melody over the tonic chord. Básico: one note is moved a
/// semitone out of the key. Otherwise: one note is detuned by [cents].
Map<String, dynamic> _melody(_Spec s, int n, int cents) {
  final inst = s.inst, rng = s.rng;
  final mix = _Mix();
  // keep the melody inside the instrument's range (one semitone of margin)
  var tonic = _at(s.key, inst.melody);
  var fitting = <List<int>>[];
  while (true) {
    fitting = [
      for (final m in _melodies)
        if (m.map((d) => _degree(tonic, d)).reduce(math.max) < inst.high) m,
    ];
    if (fitting.isNotEmpty) break;
    tonic -= 12;
  }
  final melody = fitting[rng.nextInt(fitting.length)];
  final target = rng.nextInt(4);
  final notes = [for (final d in melody) _degree(tonic, d)];
  final original = notes[target];
  if (s.basic) {
    // the semitone neighbours that fall outside the key
    final out = [
      for (final step in [1, -1])
        if (!_inScale(original + step, s.key)) original + step,
    ];
    notes[target] = out[rng.nextInt(out.length)];
  }
  const step = 0.75;
  inst.chordAt(mix, _triad(inst, s.key), 0, 4 * step + 1.2, 0.5, rng);
  for (var i = 0; i < 4; i++) {
    mix.add(
      inst.note(notes[i], rng, i == target && !s.basic ? cents : 0),
      0.25 + i * step,
      i == 3 ? 1.9 : step - 0.05,
      1.0,
    );
  }
  mix.write(s.file('melody', n));
  final moved = notes[target];
  final signed = s.basic ? (moved - original) * 100 : cents;
  final upOrDown = moved > original ? 'abajo' : 'arriba';
  return _entry(
    s,
    drill: 'melody',
    n: n,
    cents: signed,
    intro: s.basic
        ? 'Escucha la melodía sobre el acorde. Una sola nota no pertenece a la tonalidad.'
        : 'Escucha la melodía sobre el acorde. Una sola nota está desafinada.',
    question: s.basic
        ? '¿Qué nota está fuera de la escala?'
        : '¿Qué nota de la melodía está desafinada?',
    options: [
      for (var i = 1; i <= 4; i++) {'id': 'n$i', 'label': 'Nota $i'},
    ],
    correct: 'n${target + 1}',
    explanation: s.basic
        ? 'La nota ${target + 1} era ${_pitchName(moved)}: no pertenece a ${s.keyName}. '
              'Dentro de la escala habría sido ${_pitchName(original)}, un semitono más $upOrDown (${inst.label}).'
        : 'La nota ${target + 1} estaba ${cents.abs()} cents ${_direction(cents)}. '
              'Las otras tres estaban afinadas. Melodía en ${s.keyName}, ${inst.label}.',
  );
}

/// A3 · I-IV-V-I cadence with a melody on top. Básico: the last note can
/// land a semitone above or below the tonic. Otherwise: detuned by [cents].
Map<String, dynamic> _final(_Spec s, int n, int cents) {
  final inst = s.inst, rng = s.rng;
  final mix = _Mix();
  final tonic = _at(s.key, inst.melody);
  // soprano mi - fa - re - do over I - IV - V - I
  final soprano = [
    _degree(tonic, 2),
    _degree(tonic, 3),
    _degree(tonic, 1),
    tonic,
  ];
  if (s.basic) soprano[3] += cents ~/ 100;
  final roots = [s.key, s.key + 5, s.key + 7, s.key];
  const step = 1.0;
  for (var i = 0; i < 4; i++) {
    final last = i == 3;
    final t = 0.05 + i * step;
    inst.chordAt(
      mix,
      _triad(inst, roots[i] % 12),
      t,
      last ? 2.8 : step - 0.05,
      0.5,
      rng,
    );
    mix.add(
      inst.note(soprano[i], rng, last && !s.basic ? cents : 0),
      t + 0.02,
      last ? 2.8 : step - 0.05,
      1.0,
    );
  }
  mix.write(s.file('final', n));
  final tonicName = _keyNames[s.key];
  final String explanation;
  if (cents == 0) {
    explanation =
        'La melodía terminaba en la tónica, $tonicName: era la nota correcta (${inst.label}).';
  } else if (s.basic) {
    explanation =
        'La melodía terminaba en ${_pitchName(soprano[3])}, un semitono más ${cents > 0 ? 'arriba' : 'abajo'} '
        'de la tónica ($tonicName). Por eso el final no cierra (${inst.label}).';
  } else {
    explanation =
        'La nota final estaba ${cents.abs()} cents ${_direction(cents)} que la tónica de ${s.keyName} (${inst.label}).';
  }
  return _entry(
    s,
    drill: 'final',
    n: n,
    cents: cents,
    intro: 'Escucha la cadencia completa y presta atención al final.',
    question: s.basic
        ? '¿La última nota es la correcta, más alta o más baja?'
        : '¿La última nota de la melodía está afinada, alta o baja?',
    options: _tuneOptions(s.basic),
    correct: _tuneAnswer(cents),
    explanation: explanation,
  );
}

/// Básico chord: a major or minor chord with the root doubled on top; in
/// the wrong version that top note is a semitone too high and clashes.
Map<String, dynamic> _wrongNote(
  _Spec s,
  int n, {
  required bool wrong,
  required bool minor,
}) {
  final inst = s.inst;
  final mix = _Mix();
  final notes = _triad(inst, s.key, minor: minor);
  final top = _at(s.key, inst.chord) + 12;
  notes.add(wrong ? top + 1 : top);
  inst.chordAt(mix, notes, 0.05, 3.2, 0.7, s.rng);
  mix.write(s.file('chord', n));
  final chord = '${_keyNames[s.key]} ${minor ? 'menor' : 'mayor'}';
  return _entry(
    s,
    drill: 'chord',
    n: n,
    cents: wrong ? 100 : 0,
    intro: 'Escucha el acorde completo.',
    question: '¿El acorde suena bien o tiene una nota equivocada?',
    options: const [
      {'id': 'ok', 'label': 'Suena bien'},
      {'id': 'wrong', 'label': 'Tiene una nota equivocada'},
    ],
    correct: wrong ? 'wrong' : 'ok',
    explanation: wrong
        ? 'Era $chord con la nota de arriba equivocada: ${_pitchName(top + 1)} en lugar de ${_keyNames[s.key]}. '
              'Choca un semitono con la raíz del acorde (${inst.label}).'
        : 'Era $chord y todas sus notas pertenecían al acorde (${inst.label}).',
    extraTags: {'quality': minor ? 'min' : 'maj'},
  );
}

/// A5 · major or minor triad whose third is in tune or detuned by [cents].
Map<String, dynamic> _third(_Spec s, int n, int cents, bool minor) {
  final inst = s.inst;
  final mix = _Mix();
  final notes = _triad(inst, s.key, minor: minor);
  // Guitar E3-G#3 samples have a fundamental and harmonics that disagree
  // by 13-17 cents: fine as accompaniment, not as the note to judge.
  // Such a third moves up an octave (on top of the chord).
  if (inst.id == 'guitar' && notes[2] >= 52 && notes[2] <= 56) {
    notes[2] += 12;
    notes.sort();
  }
  final third = notes.firstWhere((m) => (m - s.key) % 12 == (minor ? 3 : 4));
  inst.chordAt(mix, notes, 0.05, 3.2, 0.7, s.rng, detune: {third: cents});
  mix.write(s.file('third', n));
  final chord = '${_keyNames[s.key]} ${minor ? 'menor' : 'mayor'}';
  return _entry(
    s,
    drill: 'third',
    n: n,
    cents: cents,
    intro: 'Escucha el acorde completo.',
    question: '¿La tercera del acorde está afinada, alta o baja?',
    options: _tuneOptions(false),
    correct: _tuneAnswer(cents),
    explanation: cents == 0
        ? 'Era $chord (${inst.label}) y la tercera estaba afinada.'
        : 'Era $chord (${inst.label}) y la tercera estaba ${cents.abs()} cents ${_direction(cents)}.',
    extraTags: {'quality': minor ? 'min' : 'maj'},
  );
}

// -------------------------------------------------------------- instrument

class _Instrument {
  _Instrument(
    this.id,
    this.label,
    this.dir,
    this.low,
    this.high,
    this.cents, {
    required this.bass,
    required this.chord,
    required this.melody,
    required this.strumMs,
  });

  final String id, label, dir;
  final int low, high, bass, chord, melody, strumMs;
  final Map<String, double> cents; // file -> measured cents

  final _cache = <String, Float64List>{};

  static _Instrument load(
    String id,
    String label,
    String dir,
    int low,
    int high, {
    required int bass,
    required int chord,
    required int melody,
    required int strumMs,
  }) {
    final lines = File(
      '$dir/analisis_${label}_notas.csv',
    ).readAsLinesSync().skip(1);
    final cents = {
      for (final l in lines) l.split(',')[0]: double.parse(l.split(',')[3]),
    };
    return _Instrument(
      id,
      label,
      dir,
      low,
      high,
      cents,
      bass: bass,
      chord: chord,
      melody: melody,
      strumMs: strumMs,
    );
  }

  /// A note at [midi], retuned to 0 cents and then shifted by [detune],
  /// starting at its attack and level-matched (RMS of the first 300 ms).
  Float64List note(int midi, math.Random rng, int detune) {
    if (midi < low || midi > high) {
      throw RangeError('$id: $midi fuera de rango');
    }
    final take = rng.nextBool() ? '01' : '02';
    return _cache.putIfAbsent('$midi$take$detune', () {
      final file = 'sample_${id}_${_noteName(midi)}_$take.wav';
      final measured = cents[file] ?? (throw StateError('sin medición: $file'));
      var y = _shift(_readMono('$dir/cortes/$file'), measured - detune);
      var on = 0;
      while (on < y.length && y[on].abs() < 0.001) {
        on++;
      }
      y = Float64List.sublistView(y, on);
      var acc = 0.0;
      final m = math.min(y.length, 14400);
      for (var i = 0; i < m; i++) {
        acc += y[i] * y[i];
      }
      final g = 1 / math.sqrt(acc / m);
      return Float64List.fromList([for (final v in y) v * g]);
    });
  }

  /// Chord notes from low to high, strummed (guitar) or slightly spread.
  void chordAt(
    _Mix mix,
    List<int> notes,
    double t,
    double dur,
    double gain,
    math.Random rng, {
    Map<int, int> detune = const {},
  }) {
    for (var i = 0; i < notes.length; i++) {
      final offset = strumMs > 0
          ? i * strumMs / 1000
          : rng.nextDouble() * 0.012;
      mix.add(
        note(notes[i], rng, detune[notes[i]] ?? 0),
        t + offset,
        dur - offset,
        gain * (i == 0 ? 1.2 : 1.0),
      );
    }
  }
}

String _noteName(int midi) => '${_keyTokens[midi % 12]}${midi ~/ 12 - 1}';

// --------------------------------------------------------------------- mix

const _targetLufs = -25.0;
final peaks = <String, double>{};

class _Mix {
  static const sr = 48000;
  final _buf = <double>[];

  /// Adds [x] at [t] seconds, held [dur] seconds then released in 150 ms.
  void add(Float64List x, double t, double dur, double gain) {
    final st = (t * sr).round();
    final hold = (dur * sr).round(), rel = (0.15 * sr).round();
    final len = math.min(x.length, hold + rel);
    if (_buf.length < st + len) {
      _buf.addAll(List.filled(st + len - _buf.length, 0.0));
    }
    for (var i = 0; i < len; i++) {
      var g = gain;
      if (i >= hold) g *= 0.5 + 0.5 * math.cos(math.pi * (i - hold) / rel);
      _buf[st + i] += x[i] * g;
    }
  }

  void write(String path) {
    final tail = List.filled((0.1 * sr).round(), 0.0);
    final x = Float64List.fromList([..._buf, ...tail]);
    final scale = math.pow(10, (_targetLufs - _lufs(x)) / 20).toDouble();
    var peak = 0.0;
    for (var i = 0; i < x.length; i++) {
      x[i] *= scale;
      peak = math.max(peak, x[i].abs());
    }
    peaks[path] = peak;
    if (peak > 0.89) {
      stderr.writeln(
        'ALTO: $path ${(20 * math.log(peak) / math.ln10).toStringAsFixed(1)} dBFS',
      );
    }
    _writeMono16(path, x);
  }
}

/// BS.1770 integrated loudness (48 kHz K-weighting, 400 ms blocks, gated).
double _lufs(Float64List x) {
  List<double> filt(List<double> s, List<double> b, List<double> a) {
    final y = List<double>.filled(s.length, 0);
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    for (var i = 0; i < s.length; i++) {
      final v = b[0] * s[i] + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2;
      x2 = x1;
      x1 = s[i];
      y2 = y1;
      y1 = v;
      y[i] = v;
    }
    return y;
  }

  var k = filt(
    x,
    [1.53512485958697, -2.69169618940638, 1.19839281085285],
    [1.0, -1.69065929318241, 0.73248077421585],
  );
  k = filt(k, [1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621]);
  const block = 19200, hop = 4800;
  final blocks = <double>[];
  for (var s = 0; s + block <= k.length; s += hop) {
    var ms = 0.0;
    for (var i = s; i < s + block; i++) {
      ms += k[i] * k[i];
    }
    blocks.add(ms / block);
  }
  double loud(double ms) => -0.691 + 10 * math.log(ms) / math.ln10;
  var gated = blocks.where((b) => loud(b) > -70).toList();
  final rel = loud(gated.reduce((a, b) => a + b) / gated.length) - 10;
  gated = gated.where((b) => loud(b) > rel).toList();
  return loud(gated.reduce((a, b) => a + b) / gated.length);
}

// ------------------------------------------------------------------- audio

Float64List _readMono(String path) {
  final b = File(path).readAsBytesSync();
  final d = ByteData.sublistView(b);
  var p = 12, bits = 16, ch = 1;
  while (p + 8 <= b.length) {
    final idTag = String.fromCharCodes(b.sublist(p, p + 4));
    final size = d.getUint32(p + 4, Endian.little);
    if (idTag == 'fmt ') {
      ch = d.getUint16(p + 10, Endian.little);
      bits = d.getUint16(p + 22, Endian.little);
    } else if (idTag == 'data') {
      final bytes = bits ~/ 8, frames = size ~/ (bytes * ch);
      final x = Float64List(frames);
      for (var i = 0; i < frames; i++) {
        final o = p + 8 + i * bytes * ch;
        if (bits == 24) {
          var v = b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
          if (v & 0x800000 != 0) v -= 0x1000000;
          x[i] = v / 8388608;
        } else {
          x[i] = d.getInt16(o, Endian.little) / 32768;
        }
      }
      return x;
    }
    p += 8 + size + (size & 1);
  }
  throw FormatException('sin datos: $path');
}

/// Shifts the pitch DOWN by [cents] (negative raises it) with windowed-sinc
/// resampling (Blackman-Harris, 64 zero crossings per side).
Float64List _shift(Float64List x, double cents) {
  final step = math.pow(2, -cents / 1200).toDouble();
  final out = Float64List(((x.length - 1) / step).floor() + 1);
  const half = 64;
  final fc = step > 1 ? 1 / step : 1.0;
  for (var n = 0; n < out.length; n++) {
    final t = n * step, i0 = t.floor();
    var acc = 0.0;
    for (var k = i0 - half + 1; k <= i0 + half; k++) {
      if (k < 0 || k >= x.length) continue;
      final d = t - k;
      final u = (d + half) / (2 * half);
      final win =
          0.35875 -
          0.48829 * math.cos(2 * math.pi * u) +
          0.14128 * math.cos(4 * math.pi * u) -
          0.01168 * math.cos(6 * math.pi * u);
      final arg = math.pi * d * fc;
      acc += x[k] * fc * (d.abs() < 1e-12 ? 1.0 : math.sin(arg) / arg) * win;
    }
    out[n] = acc;
  }
  return out;
}

void _writeMono16(String path, Float64List x) {
  final rng = math.Random(path.hashCode);
  final n = x.length * 2;
  final d = ByteData(44 + n);
  void tag(int o, String s) {
    for (var i = 0; i < 4; i++) {
      d.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  d.setUint32(4, 36 + n, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, 1, Endian.little);
  d.setUint32(24, 48000, Endian.little);
  d.setUint32(28, 96000, Endian.little);
  d.setUint16(32, 2, Endian.little);
  d.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  d.setUint32(40, n, Endian.little);
  for (var i = 0; i < x.length; i++) {
    final dither = rng.nextDouble() - rng.nextDouble(); // TPDF, ±1 LSB
    final v = (x[i] * 32767 + dither).round().clamp(-32768, 32767);
    d.setInt16(44 + i * 2, v, Endian.little);
  }
  File(path).writeAsBytesSync(d.buffer.asUint8List());
}
