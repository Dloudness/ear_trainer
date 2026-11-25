import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'generate_filters.dart'
    show Wav, fade, hz, lufs, readWav, runSection, writeWav24;

/// Builds three EQ Avanzado practices on real material (salsa, music,
/// narration voice and acoustic guitar), all by code:
///
/// * Shelves (tags.source = shelf): low and high shelves.
///   1 Básico: what changed? (more/less lows, more/less highs, ±6 dB)
///   2 Intermedio: how much? (±3, ±6, ±9 dB)
///   3 Profesional: where does the shelf start? (+6 dB)
/// * Resonancias (resonance): one narrow, strong peak (+12 dB, Q 8), like a
///   room or a body that rings.
///   1 Básico: lows, mids or highs?  2 Intermedio: by octaves.
///   3 Profesional: by third octaves.
/// * Problemas de voz y guitarra (problem): typical tonal problems.
///   1 Básico: which of two clear opposites?  2 Intermedio: which of four?
///   3 Profesional: where is the excess? (octaves, +6 or +9 dB)
///
/// Only ONE variable changes per exercise; the clean fragment is the
/// reference. Every file is the same fragment with the same fades, at
/// -24 LUFS (a +9 dB high shelf at -23 peaked above -1 dBFS), so loudness
/// never gives the answer away. Masters go to
/// audio_masters/eq/eq_{shelves|resonances|problems}/. Then run:
///   dart run tools/compress_audio.dart
const catalogPath = 'assets/data/exercises.json';
const module = 'ecualizacionFrecuencias';
const targetLufs = -24.0;
const idPrefixes = ['EQ_SHELF_', 'EQ_RES_', 'EQ_PROB_'];

class Material {
  const Material(this.id, this.path, this.seconds, this.label);
  final String id, path, label;
  final double seconds;
}

const salsa = Material(
  'salsa',
  'audio_masters/source/music_instrumental_01.wav',
  10,
  'la salsa',
);
const music = Material(
  'music',
  'audio_masters/music/music_attention_competing_01.wav',
  13,
  'la música',
);
const voice = Material(
  'voice',
  'audio_masters/source/voice_narration_01.wav',
  10,
  'la voz',
);
const guitar = Material(
  'guitar',
  'audio_masters/source/guitar_acoustic_01.wav',
  10,
  'la guitarra',
);

/// One EQ move: [type] is bell, lowshelf or highshelf.
class Move {
  const Move(this.type, this.freq, this.gain, [this.q = 0.707]);
  final String type;
  final int freq;
  final double gain, q;

  String get token =>
      '${type}_${freq}_${gain >= 0 ? 'p' : 'm'}${gain.abs().round()}'
      '${type == 'bell' ? '_q${(q * 10).round()}' : ''}';
}

void main() {
  final exercises = <Map<String, dynamic>>[];
  final report = <String>[];

  /// Renders [material] (optionally through [move]) into [dir]; returns the
  /// app path (.m4a). Cached per file.
  final cache = <String, Wav>{};
  final written = <String>{};
  String render(String dir, Material material, Move? move) {
    final name = '${move == null ? 'reference' : move.token}_${material.id}_01';
    final appPath = 'assets/eq/$dir/$name.m4a';
    if (!written.add(name + dir)) return appPath;
    final wav = cache.putIfAbsent(material.id, () {
      final w = readWav(material.path);
      final n = min((material.seconds * w.rate).round(), w.channels[0].length);
      return Wav(w.rate, [
        for (final c in w.channels) Float64List.sublistView(c, 0, n),
      ]);
    });
    final shaped = [
      for (final c in wav.channels)
        fade(
          Float64List.fromList(move == null ? c : apply(c, wav.rate, move)),
          wav.rate,
        ),
    ];
    final loud = lufs(shaped, wav.rate);
    final gain = pow(10, (targetLufs - loud) / 20).toDouble();
    var peak = 0.0;
    for (final c in shaped) {
      for (var i = 0; i < c.length; i++) {
        c[i] *= gain;
        peak = max(peak, c[i].abs());
      }
    }
    final peakDb = 20 * log(peak) / ln10;
    report.add('$dir/$name: pico ${peakDb.toStringAsFixed(1)} dBFS');
    if (peakDb > -1) {
      stderr.writeln('$dir/$name supera -1 dBFS ($peakDb). Baja targetLufs.');
      exit(1);
    }
    Directory('audio_masters/eq/$dir').createSync(recursive: true);
    writeWav24('audio_masters/eq/$dir/$name.wav', shaped, wav.rate);
    return appPath;
  }

  Map<String, dynamic> exercise({
    required String id,
    required String source,
    required String dir,
    required Material material,
    required Move move,
    required int level,
    required String drill,
    required String question,
    required List<(String, String)> options,
    required String correct,
    required String explanation,
    required String tip,
    bool ordered = true,
    Map<String, String> tags = const {},
  }) => {
    'id': id,
    'module': module,
    'type': 'eq_band',
    'audio': {'source': 'asset', 'path': render(dir, material, move)},
    'reference': render(dir, material, null),
    'intro':
        'Compara el ejemplo con la referencia limpia. El ajuste ya está en el ejemplo.',
    'question': question,
    'options': [
      for (final (optionId, label) in options) {'id': optionId, 'label': label},
    ],
    'correct': correct,
    'difficulty': const ['beginner', 'intermediate', 'advanced'][level - 1],
    'explanation': explanation,
    'tip': tip,
    'tags': {
      'skill': source,
      'source': source,
      'material': material.id,
      'level': '$level',
      'drill': drill,
      if (ordered) 'ordered': 'true',
      'type': move.type,
      'frequency': '${move.freq}',
      'gain': '${move.gain.round()}',
      ...tags,
    },
    'access': 'free',
  };

  // ------------------------------------------------------------- shelves
  String shelfLabel(String type, double gain) =>
      '${gain > 0 ? 'Más' : 'Menos'} ${type == 'lowshelf' ? 'graves' : 'agudos'}';
  String gainLabel(double g) => '${g > 0 ? '+' : '−'}${g.abs().round()} dB';

  for (final m in [salsa, music]) {
    final src = m.id.toUpperCase();
    // L1: what changed?
    for (final (type, freq) in [
      ('lowshelf', 120),
      ('lowshelf', 250),
      ('highshelf', 4000),
      ('highshelf', 8000),
    ]) {
      for (final gain in [6.0, -6.0]) {
        final move = Move(type, freq, gain);
        exercises.add(
          exercise(
            id: 'EQ_SHELF_L1_${move.token.toUpperCase()}_$src',
            source: 'shelf',
            dir: 'eq_shelves',
            material: m,
            move: move,
            level: 1,
            drill: 'change',
            question: '¿Qué cambió en el ejemplo?',
            options: [
              ('lowshelf_p', 'Más graves'),
              ('lowshelf_m', 'Menos graves'),
              ('highshelf_p', 'Más agudos'),
              ('highshelf_m', 'Menos agudos'),
            ],
            correct: '${type}_${gain > 0 ? 'p' : 'm'}',
            explanation:
                '${shelfLabel(type, gain)}: un shelf de ${type == 'lowshelf' ? 'graves' : 'agudos'} '
                'de ${gainLabel(gain)} desde ${hz(freq)}. Un shelf sube o baja todo lo que está '
                '${type == 'lowshelf' ? 'por debajo' : 'por encima'} de esa frecuencia, como un escalón.',
            tip:
                'Compara con la referencia: ¿cambió el peso (los graves) o el brillo (los agudos)? '
                '¿Hay más o hay menos?',
          ),
        );
      }
    }
    // L2: how much?
    for (final (type, freq) in [('lowshelf', 200), ('highshelf', 5000)]) {
      const gains = [9.0, 6.0, 3.0, -3.0, -6.0, -9.0];
      for (final gain in gains) {
        final move = Move(type, freq, gain);
        final zone = type == 'lowshelf' ? 'graves' : 'agudos';
        exercises.add(
          exercise(
            id: 'EQ_SHELF_L2_${move.token.toUpperCase()}_$src',
            source: 'shelf',
            dir: 'eq_shelves',
            material: m,
            move: move,
            level: 2,
            drill: 'gain',
            question: 'Shelf de $zone en ${hz(freq)}. ¿Cuánto se ajustó?',
            options: [for (final g in gains) ('g${g.round()}', gainLabel(g))],
            correct: 'g${gain.round()}',
            explanation:
                'Era un shelf de $zone de ${gainLabel(gain)} desde ${hz(freq)}. '
                '${gain.abs() == 3
                    ? 'Con 3 dB el cambio es sutil, de los que se hacen al pulir una mezcla.'
                    : gain.abs() == 6
                    ? 'Con 6 dB el cambio es claro sin exagerar.'
                    : 'Con 9 dB el cambio es fuerte: transforma el color de la mezcla.'}',
            tip:
                'Primero decide si subió o bajó; después, si el cambio es sutil (3), claro (6) o fuerte (9).',
          ),
        );
      }
    }
    // L3: where does it start?
    for (final (type, freqs) in [
      ('lowshelf', [100, 200, 400, 800]),
      ('highshelf', [2000, 4000, 8000, 12000]),
    ]) {
      for (final freq in freqs) {
        final move = Move(type, freq, 6);
        final zone = type == 'lowshelf' ? 'graves' : 'agudos';
        exercises.add(
          exercise(
            id: 'EQ_SHELF_L3_${move.token.toUpperCase()}_$src',
            source: 'shelf',
            dir: 'eq_shelves',
            material: m,
            move: move,
            level: 3,
            drill: 'frequency',
            question: 'Shelf de $zone de +6 dB. ¿En qué frecuencia está?',
            options: [for (final f in freqs) ('f$f', hz(f))],
            correct: 'f$freq',
            explanation:
                'El shelf está en ${hz(freq)}. ${shelfWhere(type, freq)}',
            tip: type == 'lowshelf'
                ? 'Cuanto más alto el shelf de graves, más instrumentos engorda: primero el bombo y el bajo, después el piano y las voces.'
                : 'Cuanto más bajo el shelf de agudos, más se ilumina todo: primero el aire de los platillos, después la presencia de las voces.',
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------- resonances
  const octaves = [125, 250, 500, 1000, 2000, 4000, 8000];
  const thirds = [
    250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, //
  ];
  List<int> nearest(List<int> set, int f) {
    final i = set.indexOf(f);
    final start = (i - 1).clamp(0, set.length - 4);
    return set.sublist(start, start + 4);
  }

  for (final m in [voice, guitar]) {
    final src = m.id.toUpperCase();
    Map<String, dynamic> res(
      int level,
      String drill,
      int freq,
      String question,
      List<(String, String)> options,
      String correct,
      String explanation,
    ) {
      final move = Move('bell', freq, 12, 8);
      return exercise(
        id: 'EQ_RES_L${level}_${freq}_$src',
        source: 'resonance',
        dir: 'eq_resonances',
        material: m,
        move: move,
        level: level,
        drill: drill,
        question: question,
        options: options,
        correct: correct,
        explanation: explanation,
        tip:
            'Una resonancia es una nota que "silba" o "zumba" por encima del resto. '
            'Tararéala: si la puedes cantar, ya sabes en qué zona está.',
      );
    }

    // L1: lows, mids or highs?
    for (final (freq, zone) in [
      (150, 'graves'),
      (220, 'graves'),
      (700, 'medios'),
      (1200, 'medios'),
      (3500, 'agudos'),
      (6000, 'agudos'),
    ]) {
      exercises.add(
        res(
          1,
          'zone',
          freq,
          '¿Dónde está la resonancia?',
          const [
            ('graves', 'Graves'),
            ('medios', 'Medios'),
            ('agudos', 'Agudos'),
          ],
          zone,
          'La resonancia está en ${hz(freq)}, en los $zone de ${m.label}: un pico angosto '
              'de +12 dB que hace sonar esa nota por encima del resto.',
        ),
      );
    }
    // L2: octaves. L3: third octaves.
    for (final freq in octaves) {
      exercises.add(
        res(
          2,
          'octave',
          freq,
          '¿En qué frecuencia está la resonancia?',
          [for (final f in nearest(octaves, freq)) ('f$f', hz(f))],
          'f$freq',
          'La resonancia está en ${hz(freq)}. ${resonanceWhere(freq)}',
        ),
      );
    }
    for (final freq in thirds) {
      exercises.add(
        res(
          3,
          'third',
          freq,
          '¿En qué frecuencia está la resonancia? (tercios de octava)',
          [for (final f in nearest(thirds, freq)) ('f$f', hz(f))],
          'f$freq',
          'La resonancia está en ${hz(freq)}. Entre tercios vecinos la diferencia es '
              'pequeña: así se busca una resonancia real antes de recortarla con un EQ angosto.',
        ),
      );
    }
  }

  // ------------------------------------------------------------ problems
  final problems = <Material, List<Problem>>{
    voice: const [
      Problem(
        'muddy',
        'Embarrada',
        Move('bell', 250, 6, 1.0),
        'le sobran medios graves alrededor de 250 Hz: suena espesa y poco clara',
      ),
      Problem(
        'boxy',
        'Encajonada',
        Move('bell', 500, 6, 1.4),
        'le sobran medios alrededor de 500 Hz: suena como dentro de una caja',
      ),
      Problem(
        'nasal',
        'Nasal',
        Move('bell', 1000, 6, 1.4),
        'le sobra 1 kHz: suena como con la nariz tapada o por teléfono',
      ),
      Problem(
        'sibilant',
        'Sibilante',
        Move('bell', 7000, 7, 2.0),
        'le sobran agudos alrededor de 7 kHz: las eses silban y cansan',
      ),
      Problem(
        'dull',
        'Apagada',
        Move('highshelf', 4000, -8),
        'le faltan agudos desde 4 kHz: suena opaca, como detrás de una tela',
      ),
      Problem(
        'thin',
        'Delgada',
        Move('lowshelf', 250, -8),
        'le faltan graves por debajo de 250 Hz: pierde cuerpo y calidez',
      ),
    ],
    guitar: const [
      Problem(
        'boomy',
        'Retumbante',
        Move('bell', 120, 6, 1.0),
        'le sobran graves alrededor de 120 Hz: la caja de la guitarra retumba',
      ),
      Problem(
        'boxy',
        'Encajonada',
        Move('bell', 500, 6, 1.4),
        'le sobran medios alrededor de 500 Hz: suena como una caja de cartón',
      ),
      Problem(
        'harsh',
        'Chillona',
        Move('bell', 3000, 6, 1.4),
        'le sobra 3 kHz: el ataque de las cuerdas se vuelve áspero',
      ),
      Problem(
        'dull',
        'Apagada',
        Move('highshelf', 4000, -8),
        'le faltan agudos desde 4 kHz: las cuerdas pierden brillo',
      ),
      Problem(
        'thin',
        'Delgada',
        Move('lowshelf', 200, -8),
        'le faltan graves por debajo de 200 Hz: pierde cuerpo',
      ),
    ],
  };
  // Clear opposites for the first level.
  const opposite = {
    'muddy': 'sibilant',
    'boxy': 'thin',
    'nasal': 'dull',
    'sibilant': 'muddy',
    'dull': 'thin',
    'thin': 'dull',
    'boomy': 'harsh',
    'harsh': 'boomy',
  };
  final rng = Random(20261125);
  for (final entry in problems.entries) {
    final m = entry.key, list = entry.value;
    final src = m.id.toUpperCase();
    final who = m == voice ? 'La voz' : 'La guitarra';
    for (final p in list) {
      final other = list.firstWhere((o) => o.id == opposite[p.id]);
      final pair = [p, other]..shuffle(rng);
      final distractors = [...list]
        ..remove(p)
        ..shuffle(rng);
      final four = [p, ...distractors.take(3)]..shuffle(rng);
      for (final (level, choices) in [(1, pair), (2, four)]) {
        exercises.add(
          exercise(
            id: 'EQ_PROB_L${level}_${p.id.toUpperCase()}_$src',
            source: 'problem',
            dir: 'eq_problems',
            material: m,
            move: p.move,
            level: level,
            drill: 'problem',
            question: '¿Qué problema tiene ${m.label}?',
            options: [for (final c in choices) (c.id, c.label)],
            correct: p.id,
            ordered: false,
            explanation: '$who está ${p.label.toLowerCase()}: ${p.why}.',
            tip:
                'Compara con la referencia limpia y ponle nombre a lo que cambió: '
                '¿sobra algo (embarrada, nasal, chillona…) o falta algo (apagada, delgada)?',
            tags: {'problem': p.id},
          ),
        );
      }
    }
    // L3: where is the excess? (a bell, octaves, +6 or +9 dB)
    final freqs = m == voice
        ? const [250, 500, 1000, 2000, 4000, 8000]
        : const [125, 250, 500, 1000, 2000, 4000];
    for (final freq in freqs) {
      for (final gain in [6.0, 9.0]) {
        final move = Move('bell', freq, gain, 1.4);
        exercises.add(
          exercise(
            id: 'EQ_PROB_L3_${freq}_P${gain.round()}_$src',
            source: 'problem',
            dir: 'eq_problems',
            material: m,
            move: move,
            level: 3,
            drill: 'frequency',
            question: 'A ${m.label} le sobra una zona. ¿En qué frecuencia?',
            options: [for (final f in nearest(freqs, freq)) ('f$f', hz(f))],
            correct: 'f$freq',
            explanation:
                'Sobran ${gainLabel(gain)} en ${hz(freq)}. ${problemWhere(m == voice, freq)}',
            tip:
                'Primero nombra el problema (embarrada, nasal, chillona…); '
                'cada nombre corresponde a una zona de frecuencias.',
          ),
        );
      }
    }
  }

  final catalog =
      jsonDecode(File(catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final list = (catalog['exercises'] as List).cast<Map<String, dynamic>>();
  final before = list.length;
  list.removeWhere(
    (e) => idPrefixes.any((p) => (e['id'] as String).startsWith(p)),
  );
  final removed = before - list.length;
  list.addAll(exercises);
  File(catalogPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );
  final worst = report
      .map(
        (r) =>
            double.parse(RegExp(r'pico (-?[\d.]+)').firstMatch(r)!.group(1)!),
      )
      .reduce(max);
  stdout.writeln('Pico máximo: ${worst.toStringAsFixed(1)} dBFS');
  for (final s in ['shelf', 'resonance', 'problem']) {
    final n = exercises.where((e) => (e['tags'] as Map)['source'] == s).length;
    stdout.writeln('  $s: $n ejercicios');
  }
  stdout.writeln(
    'Retirados: $removed · Conectados: ${exercises.length} · Audios: ${written.length}',
  );
  stdout.writeln('Ahora corre: dart run tools/compress_audio.dart');
}

class Problem {
  const Problem(this.id, this.label, this.move, this.why);
  final String id, label, why;
  final Move move;
}

String shelfWhere(String type, int freq) => switch ((type, freq)) {
  ('lowshelf', 100) => 'Solo engorda los subgraves: el bombo y el bajo.',
  ('lowshelf', 200) => 'Engorda los graves: el bajo y la base del piano.',
  ('lowshelf', 400) =>
    'Ya engorda el cuerpo de casi todo: la mezcla se vuelve pesada.',
  ('lowshelf', 800) =>
    'Llega a los medios: todo suena más grueso y menos claro.',
  ('highshelf', 2000) =>
    'Abarca la presencia: las voces y la percusión se adelantan.',
  ('highshelf', 4000) =>
    'Realza el brillo: platillos y consonantes más definidos.',
  ('highshelf', 8000) => 'Solo el brillo alto: los platillos y el aire.',
  _ => 'Solo el aire: un cambio fino, arriba de todo.',
};

String resonanceWhere(int freq) => switch (freq) {
  125 => 'En los graves: un zumbido grave, como un cuarto que retumba.',
  250 => 'En los medios graves: un zumbido que espesa el sonido.',
  500 => 'En los medios: un tono hueco, como de caja.',
  1000 => 'En los medios: un tono nasal que se queda sonando.',
  2000 => 'En los medios agudos: un tono duro, metálico.',
  4000 => 'En la presencia: un silbido punzante.',
  _ => 'En los agudos: un silbido fino.',
};

String problemWhere(bool isVoice, int freq) => switch (freq) {
  125 => 'Es el retumbe de la caja de la guitarra.',
  250 =>
    isVoice
        ? 'Es la zona que embarra la voz.'
        : 'Es la zona que engorda y embarra la guitarra.',
  500 => 'Es la zona que suena a caja.',
  1000 =>
    isVoice ? 'Es la zona nasal.' : 'Es la zona nasal, con tono de radio.',
  2000 => 'Es la zona dura de los medios agudos.',
  4000 =>
    isVoice
        ? 'Es la presencia: en exceso, chillona.'
        : 'Es el ataque de las cuerdas: en exceso, chillón.',
  _ => 'Es la zona de las eses y el aire.',
};

// ---------------------------------------------------------------- DSP

/// Applies [move] with an RBJ cookbook biquad (bell or shelf).
Float64List apply(Float64List x, int rate, Move move) {
  final a = pow(10, move.gain / 40).toDouble();
  final w = 2 * pi * move.freq / rate;
  final c = cos(w), s = sin(w);
  final List<double> b, d;
  if (move.type == 'bell') {
    final alpha = s / (2 * move.q);
    b = [1 + alpha * a, -2 * c, 1 - alpha * a];
    d = [1 + alpha / a, -2 * c, 1 - alpha / a];
  } else {
    // Shelf slope S = 1.
    final alpha = s / 2 * sqrt(2);
    final r = 2 * sqrt(a) * alpha;
    if (move.type == 'lowshelf') {
      b = [
        a * ((a + 1) - (a - 1) * c + r),
        2 * a * ((a - 1) - (a + 1) * c),
        a * ((a + 1) - (a - 1) * c - r),
      ];
      d = [
        (a + 1) + (a - 1) * c + r,
        -2 * ((a - 1) + (a + 1) * c),
        (a + 1) + (a - 1) * c - r,
      ];
    } else {
      b = [
        a * ((a + 1) + (a - 1) * c + r),
        -2 * a * ((a - 1) + (a + 1) * c),
        a * ((a + 1) + (a - 1) * c - r),
      ];
      d = [
        (a + 1) - (a - 1) * c + r,
        2 * ((a - 1) - (a + 1) * c),
        (a + 1) - (a - 1) * c - r,
      ];
    }
  }
  return runSection(x, [
    b[0] / d[0],
    b[1] / d[0],
    b[2] / d[0],
    d[1] / d[0],
    d[2] / d[0],
  ]);
}
