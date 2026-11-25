import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates the synthetic exercises that need no recording:
///
/// * T1 `tone_frequency`: which band is this pure tone? Level 1: octaves
///   (63 Hz to 16 kHz); level 2: third-octave bands, closer together.
/// * T2 `tone_compare`: is the second tone higher or lower?
/// * A1 `pitch_tuning`: is the second note in tune, sharp or flat?
///
/// Writes WAV files (44.1 kHz, 16-bit, mono) and replaces the TONE_ and
/// PITCH_ entries of assets/data/exercises.json. Run from the project root:
/// `dart tools/generate_tones.dart`.
const sampleRate = 44100;
const tonesDir = 'audio_masters/tones';
const pitchDir = 'audio_masters/pitch';
const catalogPath = 'assets/data/exercises.json';

void main() {
  final generated = <Map<String, dynamic>>[
    ..._toneFrequency(),
    ..._toneCompare(),
    ..._pitchTuning(),
  ];

  final catalog =
      jsonDecode(File(catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final exercises = (catalog['exercises'] as List).cast<Map<String, dynamic>>();
  final before = exercises.length;
  exercises.removeWhere((exercise) {
    final id = exercise['id'] as String;
    return id.startsWith('TONE_') || id.startsWith('PITCH_');
  });
  final removed = before - exercises.length;
  exercises.addAll(generated);
  File(catalogPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );

  stdout.writeln('Retirados: $removed');
  stdout.writeln('Generados: ${generated.length}');
  for (final type in ['tone_frequency', 'tone_compare', 'pitch_tuning']) {
    final count = generated.where((e) => e['type'] == type).length;
    stdout.writeln('  $type: $count');
  }
}

// ---------------------------------------------------------------- T1

/// Level 1: octave bands, 63 Hz to 16 kHz.
const _bands = [63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

/// Level 2: third-octave bands (ISO nominal), 50 Hz to 16 kHz.
const _thirds = [
  50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, //
  1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000,
];

String _hz(int frequency) {
  if (frequency < 1000) return '$frequency Hz';
  final khz = (frequency / 1000).toString().replaceAll(RegExp(r'\.0$'), '');
  return '${khz.replaceAll('.', ',')} kHz';
}

String _region(int frequency) => switch (frequency) {
  <= 80 => 'los subgraves',
  <= 200 => 'los graves',
  <= 400 => 'los medios graves',
  <= 1250 => 'los medios',
  <= 3150 => 'los medios agudos',
  <= 6300 => 'la presencia',
  <= 12500 => 'el brillo y el aire',
  _ => 'el aire más alto (no todos lo oyen)',
};

List<Map<String, dynamic>> _toneFrequency() {
  // Several loudness levels per band so volume never gives the answer away.
  const loudness = {'01': 0.30, '02': 0.14, '03': 0.21};
  final result = <Map<String, dynamic>>[];
  final written = <String>{};
  String tone(int frequency, String take) {
    final path = '$tonesDir/tone_pure_${frequency}_$take.wav';
    if (written.add(path)) {
      _writeWav(path, _sine(frequency.toDouble(), 2.5, loudness[take]!));
    }
    return path;
  }

  Map<String, dynamic> entry({
    required String id,
    required int level,
    required int frequency,
    required String path,
    required List<int> choices,
    int? maxOptions,
  }) => {
    'id': id,
    'module': 'ecualizacionFrecuencias',
    'type': 'tone_frequency',
    'audio': {'source': 'asset', 'path': path},
    'intro': 'Escucha el tono puro e identifica su frecuencia.',
    'question': '¿Qué frecuencia escuchas?',
    'options': [
      for (final band in choices) {'id': 'f$band', 'label': _hz(band)},
    ],
    'maxOptions': ?maxOptions,
    'correct': 'f$frequency',
    'difficulty': level == 1 ? 'beginner' : 'intermediate',
    'explanation': 'Es un tono de ${_hz(frequency)}, en ${_region(frequency)}.',
    'tags': {
      'skill': 'pure_tone',
      'level': '$level',
      'frequency': '$frequency',
    },
    'access': 'free',
  };

  // Level 1: any four octave bands, one of them the answer.
  for (final frequency in _bands) {
    for (final take in loudness.keys) {
      result.add(
        entry(
          id: 'TONE_FREQ_${frequency}_$take',
          level: 1,
          frequency: frequency,
          path: tone(frequency, take),
          choices: _bands,
          maxOptions: 4,
        ),
      );
    }
  }
  // Level 2: the answer and its closest third-octave neighbours.
  for (var i = 0; i < _thirds.length; i++) {
    final frequency = _thirds[i];
    final start = (i - 1).clamp(0, _thirds.length - 4);
    final choices = _thirds.sublist(start, start + 4);
    for (final take in ['01', '02']) {
      result.add(
        entry(
          id: 'TONE_THIRD_${frequency}_$take',
          level: 2,
          frequency: frequency,
          path: tone(frequency, take),
          choices: choices,
        ),
      );
    }
  }
  return result;
}

// ---------------------------------------------------------------- T2

const _compareBases = [220.0, 330.0, 440.0, 660.0, 880.0];
const _compareCents = {100: 'beginner', 50: 'intermediate', 25: 'advanced'};

String _centsWords(int cents) => switch (cents) {
  100 => 'un semitono',
  50 => 'medio semitono',
  25 => 'un cuarto de semitono',
  10 => 'una diferencia muy pequeña (10 cents)',
  _ => '$cents cents',
};

List<Map<String, dynamic>> _toneCompare() {
  final result = <Map<String, dynamic>>[];
  for (final base in _compareBases) {
    for (final entry in _compareCents.entries) {
      for (final up in [true, false]) {
        final cents = entry.key;
        final second = base * pow(2, (up ? cents : -cents) / 1200);
        final direction = up ? 'up' : 'down';
        final path =
            '$tonesDir/tone_compare_${base.round()}_${direction}_${cents}c_01.wav';
        _writeWav(path, [
          ..._sine(base, 1.0, 0.28),
          ..._silence(0.45),
          ..._sine(second, 1.0, 0.28),
        ]);
        result.add({
          'id': 'TONE_CMP_${base.round()}_${direction.toUpperCase()}_${cents}C',
          'module': 'ecualizacionFrecuencias',
          'type': 'tone_compare',
          'audio': {'source': 'asset', 'path': path},
          'intro': 'Escucha dos tonos seguidos y compara su altura.',
          'question': '¿El segundo tono es más agudo o más grave?',
          'options': [
            {'id': 'higher', 'label': 'Más agudo'},
            {'id': 'lower', 'label': 'Más grave'},
          ],
          'correct': up ? 'higher' : 'lower',
          'difficulty': entry.value,
          'explanation':
              'El segundo tono es más ${up ? 'agudo' : 'grave'}: '
              '${up ? 'sube' : 'baja'} ${_centsWords(cents)}.',
          'tags': {
            'skill': 'pitch_compare',
            'base': '${base.round()}',
            'cents': '${up ? cents : -cents}',
          },
          'access': 'free',
        });
      }
    }
  }
  return result;
}

// ---------------------------------------------------------------- A1

const _notes = {'c4': 261.63, 'e4': 329.63, 'g4': 392.00, 'a4': 440.00};
const _noteNames = {'c4': 'Do', 'e4': 'Mi', 'g4': 'Sol', 'a4': 'La'};
const _detune = {50: 'beginner', 25: 'intermediate', 10: 'advanced'};

List<Map<String, dynamic>> _pitchTuning() {
  final result = <Map<String, dynamic>>[];

  Map<String, dynamic> exercise(String note, int cents) {
    final reference = _notes[note]!;
    final tested = reference * pow(2, cents / 1200);
    final kind = cents == 0 ? 'in' : (cents > 0 ? 'up' : 'down');
    final amount = cents.abs();
    final path = cents == 0
        ? '$pitchDir/pitch_in_tune_${note}_01.wav'
        : '$pitchDir/pitch_${amount}c_${kind}_${note}_01.wav';
    _writeWav(path, [
      ..._keyTone(reference, 1.3),
      ..._silence(0.4),
      ..._keyTone(tested, 1.3),
    ]);
    final correct = switch (kind) {
      'in' => 'in_tune',
      'up' => 'sharp',
      _ => 'flat',
    };
    final noteName = _noteNames[note]!;
    final explanation = switch (kind) {
      'in' => 'Las dos notas son el mismo $noteName: está afinada.',
      'up' =>
        'La segunda nota está $amount cents alta (${_centsWords(amount)} por encima).',
      _ =>
        'La segunda nota está $amount cents baja (${_centsWords(amount)} por debajo).',
    };
    return {
      'id': cents == 0
          ? 'PITCH_IN_${note.toUpperCase()}'
          : 'PITCH_${kind.toUpperCase()}_${amount}C_${note.toUpperCase()}',
      'module': 'entrenamientoMusical',
      'type': 'pitch_tuning',
      'audio': {'source': 'asset', 'path': path},
      'intro': 'Escucha la nota de referencia y después la misma nota.',
      'question': '¿La segunda nota está afinada, alta o baja?',
      'options': [
        {'id': 'in_tune', 'label': 'Afinada'},
        {'id': 'sharp', 'label': 'Alta'},
        {'id': 'flat', 'label': 'Baja'},
      ],
      'correct': correct,
      'difficulty': cents == 0 ? 'beginner' : _detune[amount]!,
      'explanation': explanation,
      'tags': {'skill': 'tuning', 'note': note, 'cents': '$cents'},
      'access': 'free',
    };
  }

  for (final note in _notes.keys) {
    // One in-tune example per note keeps "Afinada" a real possibility.
    result.add(exercise(note, 0));
    for (final cents in _detune.keys) {
      result.add(exercise(note, cents));
      result.add(exercise(note, -cents));
    }
  }
  return result;
}

// ---------------------------------------------------------------- audio

/// Pure sine with 30 ms fades.
List<double> _sine(double frequency, double seconds, double amplitude) {
  final count = (seconds * sampleRate).round();
  final fade = (0.03 * sampleRate).round();
  return List<double>.generate(count, (i) {
    final envelope = min(1.0, min(i / fade, (count - 1 - i) / fade));
    return amplitude * envelope * sin(2 * pi * frequency * i / sampleRate);
  });
}

/// Soft keyboard-like tone: a few harmonics with a gentle decay, so the
/// pitch is clear and it sounds more musical than a bare sine.
List<double> _keyTone(double frequency, double seconds) {
  const harmonics = [1.0, 0.45, 0.22, 0.12, 0.06];
  final count = (seconds * sampleRate).round();
  final attack = (0.01 * sampleRate).round();
  final release = (0.08 * sampleRate).round();
  final norm = harmonics.reduce((a, b) => a + b);
  return List<double>.generate(count, (i) {
    final t = i / sampleRate;
    var value = 0.0;
    for (var h = 0; h < harmonics.length; h++) {
      value += harmonics[h] * sin(2 * pi * frequency * (h + 1) * t);
    }
    final decay = exp(-1.6 * t);
    final edge = min(1.0, min(i / attack, (count - 1 - i) / release));
    return 0.32 * value / norm * decay * edge;
  });
}

List<double> _silence(double seconds) =>
    List<double>.filled((seconds * sampleRate).round(), 0);

void _writeWav(String path, List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
  }
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data.buffer.asUint8List());
}
