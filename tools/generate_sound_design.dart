import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'generate_filters.dart' show Wav, lufs, readWav, runSection, writeWav24;

/// Builds Diseño sonoro, level Básico (module disenoSonoro, Premium), from
/// the material already in the project, all by code:
///
/// * ¿Qué ambiente es? (drill ambience): 8 s of an ambience. The wrong
///   options are sounds that resemble it (rain → river, frying).
/// * ¿Qué le pasa a esta toma? (take): the narration voice with ONE subtle
///   problem, or clean (about a third). Options come in pairs that are easy
///   to confuse: hum ↔ boomy voice, air conditioning ↔ background rain,
///   dull voice ↔ light distortion.
/// * ¿Qué ajustarías en esta mezcla? (mix): voice and music at -3, -15 or
///   -26 dB → lower the music, fine, raise the music.
/// * ¿Cuánta reverberación tiene esta toma? (reverb): dry, a little room or
///   a lot of room (algorithmic room, by code).
/// * ¿Se pueden pegar estas dos tomas? (continuity): the voice cut in two
///   takes; the background under the second take is the same, louder or
///   softer, or different.
///
/// Only one thing changes per exercise. Every file is at -23 LUFS, so
/// loudness never gives the answer away. Masters go to
/// audio_masters/sound_design/(drill)/. Then run:
///   dart run tools/compress_audio.dart
const catalogPath = 'assets/data/exercises.json';
const module = 'disenoSonoro';
const idPrefix = 'SD_';
const targetLufs = -23.0;
const rate = 48000;

final _rng = Random(11);

// ── Material ────────────────────────────────────────────────────────────

class Ambience {
  const Ambience(this.file, this.id, this.label, this.explain, this.lookalikes);
  final String file;
  final String id;
  final String label;
  final String explain;

  /// Places that sound similar: the tempting wrong answers.
  final List<String> lookalikes;
  String get path => 'audio_masters/ambient/$file.wav';
}

const ambiences = [
  Ambience(
    'ambient_coffe_shop',
    'cafe',
    'Cafetería con gente',
    'Es una cafetería: murmullo de conversaciones mezclado con loza, tazas y cubiertos. Una oficina tendría teclados y teléfonos; un aula, una voz que domina.',
    ['Oficina con gente', 'Aula de clase', 'Estación de bus'],
  ),
  Ambience(
    'Rain_Street_Neighborhood_01',
    'rain_city',
    'Lluvia en la ciudad',
    'Es lluvia en la ciudad: miles de gotas pequeñas sobre superficies duras, con la calle de fondo. Un río fluye más parejo y grave; una fritura chisporrotea más agudo y seco.',
    ['Río o quebrada', 'Fritura en una sartén', 'Viento helado'],
  ),
  Ambience(
    'ambient_field_cold_rain_01',
    'rain_field',
    'Lluvia en el campo',
    'Es lluvia en el campo: gotas sobre hojas y tierra, más suaves que sobre la calle. Un río fluye parejo y grave; una fritura chisporrotea más agudo y seco.',
    ['Río o quebrada', 'Fritura en una sartén', 'Viento helado'],
  ),
  Ambience(
    'ambient_field_birds_01',
    'birds',
    'Campo con pájaros',
    'Es un campo con pájaros: cantos que aparecen y se alejan sobre un fondo abierto y tranquilo. En un parque de ciudad se oirían tráfico y gente lejos.',
    ['Parque en la ciudad', 'Noche con insectos', 'Jaula de aves en un zoológico'],
  ),
  Ambience(
    'Wind_birds_01',
    'wind_birds',
    'Bosque con viento y pájaros',
    'Es un bosque con viento: ráfagas entre los árboles y pájaros a lo lejos. En la playa se oiría el ritmo de las olas; en un parque de ciudad, tráfico y gente.',
    ['Parque en la ciudad', 'Playa con gaviotas', 'Noche con insectos'],
  ),
  Ambience(
    'ambient_insects_nigth_01',
    'night',
    'Noche con insectos',
    'Es una noche con insectos: grillos y chicharras que repiten un patrón agudo y constante. Un zumbido eléctrico sería un tono fijo, sin ese pulso.',
    ['Campo con pájaros', 'Zumbido eléctrico de una lámpara', 'Lluvia suave'],
  ),
  Ambience(
    'ambient_insects_nigth_02',
    'night',
    'Noche con insectos',
    'Es una noche con insectos: grillos y chicharras que repiten un patrón agudo y constante. Un zumbido eléctrico sería un tono fijo, sin ese pulso.',
    ['Campo con pájaros', 'Zumbido eléctrico de una lámpara', 'Lluvia suave'],
  ),
  Ambience(
    'wind_snow_cold_01',
    'wind',
    'Viento helado',
    'Es viento: ráfagas que crecen y bajan, sin gotas ni cantos. El mar tendría el ritmo de las olas; el tráfico, motores que pasan.',
    ['Mar con oleaje', 'Tráfico lejano', 'Lluvia en la ciudad'],
  ),
];

const voicePath = 'audio_masters/source/voice_narration_01.wav';

/// The pieces chosen by the professor for dialogue under music.
const musicPieces = [
  'music_epic_strings_01',
  'music_tension_strings_01',
  'strings_epic_01',
  'strings_tesion_01',
];

// ── Main ────────────────────────────────────────────────────────────────

void main() {
  final exercises = <Map<String, dynamic>>[];
  final report = <String>[];
  final cache = <String, Wav>{};
  Wav load(String path) => cache.putIfAbsent(path, () => loadAt48k(path));

  /// Normalizes [channels] to the target, checks the peak and writes the
  /// master. Returns the app path (.m4a).
  String write(String dir, String name, List<Float64List> channels) {
    final gain = pow(10, (targetLufs - lufs(channels, rate)) / 20).toDouble();
    var peak = 0.0;
    for (final c in channels) {
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
    Directory('audio_masters/sound_design/$dir').createSync(recursive: true);
    writeWav24('audio_masters/sound_design/$dir/$name.wav', channels, rate);
    return 'assets/sound_design/$dir/$name.m4a';
  }

  Map<String, dynamic> exercise({
    required String id,
    required String drill,
    required String path,
    required String intro,
    required String question,
    required List<Map<String, String>> options,
    required String correct,
    required String explanation,
    required String tip,
    int? maxOptions,
    bool ordered = false,
    String? material,
  }) => {
    'id': id,
    'module': module,
    'type': 'sd_choice',
    'audio': {'source': 'asset', 'path': path},
    'intro': intro,
    'question': question,
    'options': options,
    'maxOptions': ?maxOptions,
    'correct': correct,
    'difficulty': 'beginner',
    'explanation': explanation,
    'tip': tip,
    'tags': {
      'drill': drill,
      'skill': drill,
      'level': '1',
      if (ordered) 'ordered': 'true',
      'material': ?material,
    },
    'access': 'premium',
  };

  // 1 · ¿Qué ambiente es? ─────────────────────────────────────────────────
  const clip = 8.0;
  var n = 0;
  for (final ambience in ambiences) {
    final wav = load(ambience.path);
    final seconds = wav.channels[0].length / rate;
    final count = (seconds / 12).floor().clamp(1, 4);
    for (var i = 0; i < count; i++) {
      final start = count == 1
          ? (seconds - clip) / 2
          : (seconds - clip) * (i + 0.5) / count;
      final name = 'sd_ambience_${ambience.file.toLowerCase()}_${pad(i + 1)}';
      final audio = safeClip(wav, start, clip);
      if (audio == null) {
        report.add('ambience/$name: omitido, sus golpes pasan de -1 dBFS');
        continue;
      }
      n++;
      exercises.add(
        exercise(
          id: 'SD_AMB_${pad(n)}',
          drill: 'ambience',
          path: write('ambience', name, audio),
          intro: 'Cierra los ojos. Escucha el lugar.',
          question: '¿Qué ambiente es?',
          options: [
            {'id': ambience.id, 'label': ambience.label},
            for (final (k, label) in ambience.lookalikes.indexed)
              {'id': 'alt$k', 'label': label},
          ],
          maxOptions: 3,
          correct: ambience.id,
          explanation: ambience.explain,
          tip:
              'Busca el detalle que delata el lugar: loza, motores, gotas sobre una superficie, el pulso de un insecto.',
          material: ambience.file,
        ),
      );
    }
  }

  // 2 · ¿Qué le pasa a esta toma? ─────────────────────────────────────────
  final voice = load(voicePath);
  final voiceLen = voice.channels[0].length;
  final voiceLufs = lufs(voice.channels, rate);

  List<Float64List> under(List<Float64List> noise, double lu) {
    final scale =
        pow(10, (voiceLufs - lu - lufs(noise, rate)) / 20).toDouble();
    return [
      for (var c = 0; c < 2; c++)
        Float64List.fromList([
          for (var i = 0; i < voiceLen; i++)
            voice.channels[c][i] + noise[c][i] * scale,
        ]),
    ];
  }

  List<Float64List> each(List<double> Function(Float64List) f) => [
    for (final c in voice.channels) Float64List.fromList(f(c)),
  ];

  const takeLabels = {
    'hum': 'Zumbido eléctrico',
    'boomy': 'Voz retumbante: le sobran graves',
    'air': 'Ruido de aire acondicionado',
    'rain': 'Lluvia de fondo',
    'dull': 'Voz apagada: le faltan agudos',
    'distorted': 'Voz saturada (distorsión)',
    'clean': 'Nada, la toma está limpia',
  };
  const twins = {
    'hum': 'boomy',
    'boomy': 'hum',
    'air': 'rain',
    'rain': 'air',
    'dull': 'distorted',
    'distorted': 'dull',
  };
  const takeExplain = {
    'hum':
        'Hay un zumbido grave y constante de 60 Hz, el de la red eléctrica: un tono fijo que no cambia con la voz. Suele venir de cables, luces o una mala tierra. La voz retumbante también suena grave, pero solo cuando la persona habla.',
    'boomy':
        'A la voz le sobran graves (alrededor de 200 Hz): suena embarrada y retumba, como si el micrófono estuviera muy cerca o en una sala pequeña. A diferencia del zumbido, el exceso desaparece cuando la persona calla.',
    'air':
        'Hay un ruido continuo de aire acondicionado: un soplido parejo con un leve tono de motor. Se nota en las pausas. La lluvia tendría gotas, pequeños golpes irregulares.',
    'rain':
        'Hay lluvia de fondo: un ruido ancho hecho de miles de gotas pequeñas e irregulares. El aire acondicionado sería un soplido parejo, sin gotas.',
    'dull':
        'A la voz le faltan agudos: suena apagada, como detrás de una tela o con el micrófono mal orientado. No hay distorsión: el sonido es limpio, solo opaco.',
    'distorted':
        'La voz está saturada: en las sílabas fuertes aparece una aspereza, el sonido "se rompe". Pasa cuando la ganancia de entrada está muy alta. Una voz apagada pierde brillo, pero no se rompe.',
    'clean':
        'La toma está limpia: no hay ruidos debajo y la voz tiene sus graves y agudos naturales. Saber reconocer una toma buena es tan importante como detectar un problema.',
  };

  final takes = <(String, String, List<Float64List>)>[
    ('hum', 'soft', under(hum(voiceLen, buzz: false), 24)),
    ('hum', 'buzz', under(hum(voiceLen, buzz: true), 26)),
    ('boomy', '180', each((c) => peaking(c, 180, 1.0, 9))),
    ('boomy', '250', each((c) => peaking(c, 250, 1.0, 8))),
    ('air', 'a', under(airConditioner(voiceLen, seed: 1), 24)),
    ('air', 'b', under(airConditioner(voiceLen, seed: 2), 22)),
    (
      'rain',
      'a',
      under(cut(load(ambiences[1].path), 40, voiceLen / rate), 22),
    ),
    (
      'rain',
      'b',
      under(cut(load(ambiences[2].path), 2, voiceLen / rate), 22),
    ),
    ('dull', '2500', each((c) => lowpass(lowpass(c, 2500), 2500))),
    ('dull', 'shelf', each((c) => highShelf(c, 3000, -14))),
    ('distorted', 'light', each((c) => saturate(c, 5))),
    ('distorted', 'strong', each((c) => saturate(c, 10))),
  ];
  final pairs = [
    ['hum', 'boomy'],
    ['air', 'rain'],
    ['dull', 'distorted'],
  ];
  var takeIndex = 0;
  void takeExercise(String correct, String path, List<String> shown) {
    takeIndex++;
    exercises.add(
      exercise(
        id: 'SD_TAKE_${pad(takeIndex)}',
        drill: 'take',
        path: path,
        intro: 'Una toma de diálogo recién grabada. Escúchala como sonidista.',
        question: '¿Qué le pasa a esta toma?',
        options: [
          for (final id in shown) {'id': id, 'label': takeLabels[id]!},
        ],
        correct: correct,
        explanation: takeExplain[correct]!,
        tip:
            'Escucha las pausas entre frases: lo que sigue sonando cuando nadie habla es ruido; lo que cambia con la voz es la voz misma.',
        material: 'voice_narration_01',
      ),
    );
  }

  for (final (kind, variant, audio) in takes) {
    final path = write('take', 'sd_take_${kind}_$variant', faded(audio, 0.05));
    final others = pairs
        .expand((p) => p)
        .where((id) => id != kind && id != twins[kind])
        .toList();
    takeExercise(kind, path, [
      kind,
      twins[kind]!,
      others[_rng.nextInt(others.length)],
      'clean',
    ]);
  }
  final cleanPath = write('take', 'sd_take_clean', faded(each((c) => c), 0.05));
  for (var i = 0; i < 6; i++) {
    final pair = pairs[i % 3];
    final others = pairs[(i + 1 + i ~/ 3) % 3];
    takeExercise('clean', cleanPath, [
      ...pair,
      others[i ~/ 3],
      'clean',
    ]);
  }

  // 3 · ¿Qué ajustarías en esta mezcla? ───────────────────────────────────
  const lead = 1.0, tail = 1.5;
  final mixLen = voiceLen + ((lead + tail) * rate).round();
  const balance = [
    ('lower', 'Bajar la música', -3.0),
    ('fine', 'Está bien así', -15.0),
    ('raise', 'Subir la música', -26.0),
  ];
  const balanceExplain = {
    'lower':
        'La música está solo 3 dB por debajo de la voz: compite con las palabras y hay que esforzarse para entender. En cine y TV, la música bajo el diálogo suele ir entre 12 y 18 dB por debajo de la voz. Había que bajarla unos 12 dB.',
    'fine':
        'La música está 15 dB por debajo de la voz, dentro del rango habitual en cine y TV (entre 12 y 18 dB por debajo del diálogo): acompaña la escena y la voz se entiende sin esfuerzo.',
    'raise':
        'La música está 26 dB por debajo de la voz: casi desaparece y la escena pierde emoción. En cine y TV suele ir entre 12 y 18 dB por debajo del diálogo. Había que subirla unos 10 dB.',
  };
  var mixIndex = 0;
  for (final piece in musicPieces) {
    final music = load('audio_masters/music/$piece.wav');
    final seconds = music.channels[0].length / rate;
    final need = mixLen / rate;
    final starts = seconds - need >= 5 ? [0.0, seconds - need] : [0.0];
    for (final (s, start) in starts.indexed) {
      final bed = faded(cut(music, start, need), 0.4);
      final bedLufs = lufs(bed, rate);
      for (final (id, _, relative) in balance) {
        final scale =
            pow(10, (voiceLufs + relative - bedLufs) / 20).toDouble();
        final offset = (lead * rate).round();
        final mix = [
          for (var c = 0; c < 2; c++)
            Float64List.fromList([
              for (var i = 0; i < mixLen; i++)
                bed[c][i] * scale +
                    (i >= offset && i - offset < voiceLen
                        ? voice.channels[c][i - offset]
                        : 0.0),
            ]),
        ];
        mixIndex++;
        exercises.add(
          exercise(
            id: 'SD_MIX_${pad(mixIndex)}',
            drill: 'mix',
            path: write('mix', 'sd_mix_${piece}_${pad(s + 1)}_$id', mix),
            intro: 'Diálogo con música de fondo. Escúchalo como editor.',
            question: '¿Qué ajustarías en esta mezcla?',
            options: [
              for (final (oid, label, _) in balance)
                {'id': oid, 'label': label},
            ],
            correct: id,
            explanation: balanceExplain[id]!,
            tip:
                'La voz manda: si tienes que esforzarte para entender una palabra, la música está muy alta. Si la música no se siente, no está aportando.',
            ordered: true,
            material: piece,
          ),
        );
      }
    }
  }

  // 4 · ¿Cuánta reverberación tiene esta toma? ───────────────────────────
  const reverbLabels = [
    ('dry', 'Seca: casi sin sala'),
    ('some', 'Un poco de sala'),
    ('lots', 'Mucha sala: se pierde la claridad'),
  ];
  const reverbExplain = {
    'dry':
        'La toma está seca: se oye la fuente casi sin reflexiones de la sala, como en un estudio tratado o con el micrófono muy cerca.',
    'some':
        'La toma tiene un poco de sala: una cola corta (alrededor de medio segundo) que da sensación de espacio sin tapar las palabras.',
    'lots':
        'La toma tiene mucha sala: una cola larga (casi dos segundos) que se monta sobre las sílabas siguientes y resta claridad. En rodaje se resuelve acercando el micrófono o tratando el lugar.',
  };
  // (id, reverb time in s, wet level in LU against the dry sound, bright)
  const rooms = [
    ('dry', 0.0, 0.0, true),
    ('dry', 0.25, -22.0, false),
    ('some', 0.5, -10.0, true),
    ('some', 0.6, -9.0, false),
    ('lots', 1.8, -2.0, true),
    ('lots', 2.0, -1.0, false),
  ];
  final reverbSources = [
    ('voice', voice),
    ('office_door', load('audio_masters/foley/foley_office_door_open_.wav')),
    ('old_door', load('audio_masters/foley/Open_door_old.wav')),
  ];
  var reverbIndex = 0;
  for (final (source, wav) in reverbSources) {
    for (final (k, (id, rt, wet, bright)) in rooms.indexed) {
      final dry = padTail(wav.channels, 2.4);
      final out = rt == 0 ? dry : addRoom(dry, rt, wet, bright: bright);
      reverbIndex++;
      exercises.add(
        exercise(
          id: 'SD_REV_${pad(reverbIndex)}',
          drill: 'reverb',
          path: write(
            'reverb',
            'sd_reverb_${source}_${id}_${pad(k + 1)}',
            faded(out, 0.05),
          ),
          intro: 'Escucha la toma y el espacio donde suena.',
          question: '¿Cuánta reverberación tiene esta toma?',
          options: [
            for (final (oid, label) in reverbLabels) {'id': oid, 'label': label},
          ],
          correct: id,
          explanation: reverbExplain[id]!,
          tip:
              'Escucha el final de cada palabra o golpe: ¿se corta en seco o queda una cola sonando en la sala?',
          ordered: true,
          material: source,
        ),
      );
    }
  }

  // 5 · ¿Se pueden pegar estas dos tomas? ────────────────────────────────
  final split = quietestPoint(voice.channels[0], 0.35, 0.65);
  const gap = 0.35; // seconds of room tone before the second take speaks
  final backgrounds = <(String, List<Float64List> Function(int, int))>[
    ('air', (len, seed) => airConditioner(len, seed: seed)),
    (
      'rain',
      (len, seed) => cut(load(ambiences[1].path), 20.0 + 30 * seed, len / rate),
    ),
    (
      'cafe',
      (len, seed) =>
          cut(load(ambiences[0].path), 10.0 + 25 * seed, len / rate),
    ),
  ];
  const continuityLabels = [
    ('yes', 'Sí, el fondo es continuo'),
    ('level', 'No: el fondo cambia de volumen'),
    ('other', 'No: aparece otro ruido de fondo'),
  ];
  const continuityExplain = {
    'yes':
        'Se pueden pegar: el fondo de las dos tomas tiene el mismo tipo de ruido y el mismo nivel, así que el corte no se nota.',
    'level':
        'No se pueden pegar así: el ruido de fondo de la segunda toma está 6 dB más alto o más bajo, y en el corte se oye un salto. Se corrige igualando el fondo o rellenando con room tone.',
    'other':
        'No se pueden pegar así: en la segunda toma aparece otro ruido de fondo (por ejemplo, un aire acondicionado o un motor que se encendió). Por eso se graba room tone en cada locación.',
  };
  var contIndex = 0;
  for (final (bgName, makeBg) in backgrounds) {
    final changes = <(String, String)>[
      ('yes', 'same1'),
      ('yes', 'same2'),
      ('level', 'up'),
      ('level', 'down'),
      ('other', 'added'),
    ];
    for (final (correct, change) in changes) {
      final first = [
        for (final c in voice.channels) Float64List.sublistView(c, 0, split),
      ];
      final second = [
        for (final c in voice.channels)
          Float64List.fromList([
            ...List<double>.filled((gap * rate).round(), 0),
            ...Float64List.sublistView(c, split),
          ]),
      ];
      final bgA = makeBg(first[0].length, 1);
      var bgB = makeBg(second[0].length, change == 'same2' ? 3 : 2);
      // Same level for both takes: 24 LU under the voice.
      final bgLevel = voiceLufs - 24;
      final scaleA = pow(10, (bgLevel - lufs(bgA, rate)) / 20).toDouble();
      var scaleB = pow(10, (bgLevel - lufs(bgB, rate)) / 20).toDouble();
      if (change == 'up') scaleB *= pow(10, 6 / 20);
      if (change == 'down') scaleB *= pow(10, -6 / 20);
      if (change == 'added') {
        final extra = bgName == 'air'
            ? cut(load(ambiences[0].path), 50, bgB[0].length / rate)
            : airConditioner(bgB[0].length, seed: 7);
        final e = pow(10, (bgLevel - 2 - lufs(extra, rate)) / 20).toDouble();
        bgB = [
          for (var c = 0; c < 2; c++)
            Float64List.fromList([
              for (var i = 0; i < bgB[c].length; i++)
                bgB[c][i] * scaleB + extra[c][i] * e,
            ]),
        ];
        scaleB = 1;
      }
      final takeA = mixInto(first, bgA, scaleA);
      final takeB = mixInto(second, bgB, scaleB);
      final edit = splice(takeA, takeB);
      contIndex++;
      exercises.add(
        exercise(
          id: 'SD_CONT_${pad(contIndex)}',
          drill: 'continuity',
          path: write(
            'continuity',
            'sd_continuity_${bgName}_$change',
            faded(edit, 0.05),
          ),
          intro:
              'Dos tomas de la misma escena, pegadas en la edición. Escucha el fondo justo en el corte.',
          question: '¿Se pueden pegar estas dos tomas?',
          options: [
            for (final (oid, label) in continuityLabels)
              {'id': oid, 'label': label},
          ],
          correct: correct,
          explanation: continuityExplain[correct]!,
          tip:
              'No escuches la voz: escucha el ruido que queda detrás, antes y después del corte. ¿Sigue igual?',
          ordered: true,
          material: 'voice_narration_01',
        ),
      );
    }
  }

  // ── Catalog ──────────────────────────────────────────────────────────
  final catalog =
      jsonDecode(File(catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final list = (catalog['exercises'] as List).cast<Map<String, dynamic>>();
  list.removeWhere((e) => (e['id'] as String).startsWith(idPrefix));
  list.addAll(exercises);
  File(catalogPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );
  final worst = report
      .where((line) => line.contains('pico '))
      .map((line) => double.parse(line.split('pico ')[1].split(' ')[0]))
      .reduce(max);
  stdout.writeln(
    '${exercises.length} ejercicios de Diseño sonoro, '
    '${report.where((l) => l.contains('pico ')).length} audios. '
    'Pico máximo: ${worst.toStringAsFixed(1)} dBFS.',
  );
  for (final drill in ['ambience', 'take', 'mix', 'reverb', 'continuity']) {
    final count = exercises
        .where((e) => (e['tags'] as Map)['drill'] == drill)
        .length;
    stdout.writeln('  $drill: $count');
  }
  for (final line in report.where((l) => l.contains('omitido'))) {
    stdout.writeln('  $line');
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────

String pad(int n) => n.toString().padLeft(2, '0');

/// Reads a master as 48 kHz stereo. Other rates go through ffmpeg (soxr)
/// into a temporary file.
Wav loadAt48k(String path) {
  var wav = readWav(path);
  if (wav.rate != rate) {
    final tmp = '${Directory.systemTemp.path}/sd_${path.hashCode}.wav';
    final result = Process.runSync('ffmpeg', [
      '-v', 'error', '-y', '-i', path, //
      '-af', 'aresample=resampler=soxr:precision=28',
      '-ar', '$rate', '-c:a', 'pcm_s24le', tmp,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln('ffmpeg no pudo convertir $path: ${result.stderr}');
      exit(1);
    }
    wav = readWav(tmp);
    File(tmp).deleteSync();
  }
  final channels = wav.channels.length == 1
      ? [wav.channels[0], Float64List.fromList(wav.channels[0])]
      : wav.channels.sublist(0, 2);
  return Wav(rate, channels);
}

/// [seconds] of [wav] from [start], as new stereo buffers.
List<Float64List> cut(Wav wav, double start, double seconds) {
  final length = wav.channels[0].length;
  final n = (seconds * rate).round();
  final int from = (start * rate).round().clamp(0, max(0, length - n));
  return [
    for (final c in wav.channels)
      Float64List.fromList([
        for (var i = 0; i < n; i++) from + i < length ? c[from + i] : 0.0,
      ]),
  ];
}

/// Raised-cosine fade in and out of [seconds].
List<Float64List> faded(List<Float64List> channels, double seconds) {
  final f = (seconds * rate).round();
  for (final c in channels) {
    final m = min(f, c.length ~/ 2);
    for (var i = 0; i < m; i++) {
      final g = 0.5 - 0.5 * cos(pi * i / m);
      c[i] *= g;
      c[c.length - 1 - i] *= g;
    }
  }
  return channels;
}

/// A faded clip of [wav] near [start] whose peak stays under -1 dBFS once
/// at the target loudness: an ambience can hide a loud hit (a car, a
/// thunder). Moves the start 2 s at a time until one fits; null if none
/// does (no limiter: it would change the sound).
List<Float64List>? safeClip(Wav wav, double start, double seconds) {
  final total = wav.channels[0].length / rate;
  for (var attempt = 0; attempt < 20; attempt++) {
    var s = start + 2.0 * attempt;
    if (s + seconds > total) s = max(0, s - (total - seconds));
    final candidate = faded(cut(wav, s, seconds), 0.3);
    final gain = pow(10, (targetLufs - lufs(candidate, rate)) / 20);
    var peak = 0.0;
    for (final c in candidate) {
      for (final v in c) {
        peak = max(peak, v.abs());
      }
    }
    if (20 * log(peak * gain) / ln10 <= -1.2) return candidate;
  }
  return null;
}

/// Mains hum: 60 Hz and its harmonics. [buzz] adds strong odd harmonics,
/// like a dimmer or a bad ground.
List<Float64List> hum(int length, {required bool buzz}) {
  final harmonics = buzz
      ? const [1.0, 0.5, 0.7, 0.3, 0.5, 0.2, 0.35, 0.1, 0.25]
      : const [1.0, 0.45, 0.2, 0.1, 0.05];
  final x = Float64List(length);
  for (var i = 0; i < length; i++) {
    final t = i / rate;
    var v = 0.0;
    for (var h = 0; h < harmonics.length; h++) {
      v += harmonics[h] * sin(2 * pi * 60 * (h + 1) * t);
    }
    x[i] = v;
  }
  return [x, Float64List.fromList(x)];
}

/// Air conditioning: pink noise darkened above ~1.5 kHz, a slow airflow
/// sway and a faint motor tone at 120 Hz.
List<Float64List> airConditioner(int length, {required int seed}) {
  final rng = Random(seed);
  List<double> channel() {
    var b0 = 0.0, b1 = 0.0, b2 = 0.0;
    final x = Float64List(length);
    for (var i = 0; i < length; i++) {
      final w = rng.nextDouble() * 2 - 1;
      b0 = 0.99765 * b0 + w * 0.0990460;
      b1 = 0.96300 * b1 + w * 0.2965164;
      b2 = 0.57000 * b2 + w * 1.0526913;
      final t = i / rate;
      final sway = 1 + 0.08 * sin(2 * pi * 0.3 * t + seed);
      x[i] = (b0 + b1 + b2 + w * 0.1848) * sway +
          0.02 * sin(2 * pi * 120 * t) +
          0.008 * sin(2 * pi * 240 * t);
    }
    return lowpass(x, 1500);
  }

  return [Float64List.fromList(channel()), Float64List.fromList(channel())];
}

/// Soft saturation (tanh) with [drive]; the level is evened out later.
List<double> saturate(Float64List x, double drive) {
  var peak = 0.0;
  for (final v in x) {
    peak = max(peak, v.abs());
  }
  final k = drive / peak;
  return [for (final v in x) _tanh(v * k)];
}

double _tanh(double v) {
  final e = exp(2 * v);
  return (e - 1) / (e + 1);
}

/// RBJ biquads.
List<double> peaking(Float64List x, double f, double q, double gainDb) {
  final a = pow(10, gainDb / 40).toDouble();
  final w = 2 * pi * f / rate;
  final alpha = sin(w) / (2 * q);
  final c = cos(w);
  final d0 = 1 + alpha / a;
  return runSection(x, [
    (1 + alpha * a) / d0,
    -2 * c / d0,
    (1 - alpha * a) / d0,
    -2 * c / d0,
    (1 - alpha / a) / d0,
  ]);
}

Float64List lowpass(List<double> input, double f) {
  final x = input is Float64List ? input : Float64List.fromList(input);
  final w = 2 * pi * f / rate;
  final alpha = sin(w) / (2 * sqrt1_2);
  final c = cos(w);
  final d0 = 1 + alpha;
  return runSection(x, [
    (1 - c) / 2 / d0,
    (1 - c) / d0,
    (1 - c) / 2 / d0,
    -2 * c / d0,
    (1 - alpha) / d0,
  ]);
}

List<double> highShelf(Float64List x, double f, double gainDb) {
  final a = pow(10, gainDb / 40).toDouble();
  final w = 2 * pi * f / rate;
  final c = cos(w), s = sin(w);
  final alpha = s / 2 * sqrt(2);
  final r = 2 * sqrt(a) * alpha;
  final b0 = a * ((a + 1) + (a - 1) * c + r);
  final b1 = -2 * a * ((a - 1) + (a + 1) * c);
  final b2 = a * ((a + 1) + (a - 1) * c - r);
  final d0 = (a + 1) - (a - 1) * c + r;
  final d1 = 2 * ((a - 1) - (a + 1) * c);
  final d2 = (a + 1) - (a - 1) * c - r;
  return runSection(x, [b0 / d0, b1 / d0, b2 / d0, d1 / d0, d2 / d0]);
}

/// [channels] followed by [seconds] of silence, so a reverb tail fits.
List<Float64List> padTail(List<Float64List> channels, double seconds) => [
  for (final c in channels)
    Float64List.fromList([
      ...c,
      ...List<double>.filled((seconds * rate).round(), 0),
    ]),
];

/// Adds an algorithmic room (Freeverb-style: early reflections, eight
/// parallel combs and four allpasses per side) with reverb time [rt]
/// seconds, its level [wetLu] LU against the dry sound. [bright] keeps more
/// highs in the tail.
List<Float64List> addRoom(
  List<Float64List> dry,
  double rt,
  double wetLu, {
  required bool bright,
}) {
  const combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
  const allpasses = [556, 441, 341, 225];
  const spread = 23;
  final scale = rate / 44100;
  final damp = bright ? 0.2 : 0.5;
  final length = dry[0].length;
  final mono = Float64List(length);
  for (var i = 0; i < length; i++) {
    mono[i] = (dry[0][i] + dry[1][i]) / 2;
  }
  // Pre-delay 15 ms and two early reflections.
  final pre = (0.015 * rate).round();
  final input = Float64List(length);
  for (var i = 0; i < length; i++) {
    input[i] = (i >= pre ? mono[i - pre] : 0) +
        (i >= pre * 2 ? 0.5 * mono[i - pre * 2] : 0) +
        (i >= pre * 3 ? 0.3 * mono[i - pre * 3] : 0);
  }
  List<Float64List> wet = [];
  for (var side = 0; side < 2; side++) {
    final out = Float64List(length);
    for (final base in combs) {
      final d = ((base + side * spread) * scale).round();
      final g = pow(10, -3 * d / (rt * rate)).toDouble();
      final buf = Float64List(d);
      var idx = 0;
      var store = 0.0;
      for (var i = 0; i < length; i++) {
        final y = buf[idx];
        store = y * (1 - damp) + store * damp;
        buf[idx] = input[i] + store * g;
        idx = (idx + 1) % d;
        out[i] += y;
      }
    }
    var signal = out;
    for (final base in allpasses) {
      final d = ((base + side * spread) * scale).round();
      final buf = Float64List(d);
      var idx = 0;
      final next = Float64List(length);
      for (var i = 0; i < length; i++) {
        final b = buf[idx];
        final v = signal[i];
        next[i] = -v + b;
        buf[idx] = v + b * 0.5;
        idx = (idx + 1) % d;
      }
      signal = next;
    }
    wet.add(signal);
  }
  final k =
      pow(10, (lufs(dry, rate) + wetLu - lufs(wet, rate)) / 20).toDouble();
  return [
    for (var c = 0; c < 2; c++)
      Float64List.fromList([
        for (var i = 0; i < length; i++) dry[c][i] + wet[c][i] * k,
      ]),
  ];
}

/// Sample index of the quietest 120 ms between [from] and [to] (fractions
/// of the length): a pause where the voice can be cut in two takes.
int quietestPoint(Float64List x, double from, double to) {
  final win = (0.12 * rate).round();
  final start = (x.length * from).round();
  final end = (x.length * to).round();
  var best = start;
  var bestEnergy = double.infinity;
  for (var i = start; i + win < end; i += win ~/ 4) {
    var e = 0.0;
    for (var j = i; j < i + win; j++) {
      e += x[j] * x[j];
    }
    if (e < bestEnergy) {
      bestEnergy = e;
      best = i + win ~/ 2;
    }
  }
  return best;
}

List<Float64List> mixInto(
  List<Float64List> voice,
  List<Float64List> background,
  double scale,
) => [
  for (var c = 0; c < 2; c++)
    Float64List.fromList([
      for (var i = 0; i < voice[c].length; i++)
        voice[c][i] + background[c][i] * scale,
    ]),
];

/// Butt splice of two takes with a 10 ms crossfade, like an edit.
List<Float64List> splice(List<Float64List> a, List<Float64List> b) {
  final x = (0.010 * rate).round();
  return [
    for (var c = 0; c < 2; c++)
      Float64List.fromList([
        ...Float64List.sublistView(a[c], 0, a[c].length - x),
        for (var i = 0; i < x; i++)
          a[c][a[c].length - x + i] * (1 - i / x) + b[c][i] * (i / x),
        ...Float64List.sublistView(b[c], x),
      ]),
  ];
}
