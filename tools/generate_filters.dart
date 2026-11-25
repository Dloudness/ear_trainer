import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Builds the EQ "Filtros" practice: high-pass and low-pass filters with
/// Butterworth slopes of 6, 12, 18 and 24 dB per octave, on real music.
///
/// Levels (tags.level):
///  1 Básico: high-pass or low-pass? (12 dB/oct)
///  2 Intermedio: where is the cutoff? (octaves, 12 dB/oct)
///  3 Profesional: which slope? (6-24 dB/oct) and where is the cutoff?
///    (third octaves, 24 dB/oct)
///
/// Only ONE variable changes per exercise and the answer lives in the JSON.
/// Every file (reference included) is the same fragment with the same fades,
/// matched to -20 LUFS, so loudness never gives the answer away.
///
/// Masters go to audio_masters/eq/eq_filters/. Then run:
///   dart run tools/compress_audio.dart
const outDir = 'audio_masters/eq/eq_filters';
const appDir = 'assets/eq/eq_filters';
const catalogPath = 'assets/data/exercises.json';
const module = 'ecualizacionFrecuencias';

/// EBU R128 level. At -20 LUFS a high-pass raises the peaks above 0 dBFS
/// (its phase shift changes the waveform); -23 keeps every file below -1.
const targetLufs = -23.0;

class Source {
  const Source(this.id, this.path, this.seconds, this.label);
  final String id;
  final String path;

  /// Length of the fragment taken from the start (null: whole file).
  final double? seconds;
  final String label;
}

const sources = [
  Source(
    'salsa',
    'audio_masters/source/music_instrumental_01.wav',
    10,
    'salsa',
  ),
  Source(
    'music',
    'audio_masters/music/music_attention_competing_01.wav',
    null,
    'música',
  ),
];

enum Kind { hpf, lpf }

const octaveHpf = [100, 200, 400, 800];
const octaveLpf = [1000, 2000, 4000, 8000];
const thirdHpf = [160, 200, 250, 315];
const thirdLpf = [2000, 2500, 3150, 4000];
const slopes = [6, 12, 18, 24];
const slopeHpf = 400;
const slopeLpf = 2000;

void main() {
  Directory(outDir).createSync(recursive: true);
  final exercises = <Map<String, dynamic>>[];
  final report = <String>[];

  for (final source in sources) {
    final wav = readWav(source.path);
    var channels = wav.channels;
    if (source.seconds != null) {
      final n = min((source.seconds! * wav.rate).round(), channels[0].length);
      channels = [for (final c in channels) Float64List.sublistView(c, 0, n)];
    }

    String file(String name) => '${name}_${source.id}_01';

    /// Writes one version and returns its app path (.m4a).
    String render(String name, List<Float64List> audio) {
      final shaped = [
        for (final c in audio) fade(Float64List.fromList(c), wav.rate),
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
      report.add(
        '${file(name)}: ${loud.toStringAsFixed(1)} → $targetLufs LUFS, '
        'pico ${peakDb.toStringAsFixed(1)} dBFS',
      );
      if (peakDb > -1) {
        // Never write a file that could clip after AAC encoding.
        stderr.writeln(
          '${file(name)} supera -1 dBFS ($peakDb). Baja targetLufs.',
        );
        exit(1);
      }
      writeWav24('$outDir/${file(name)}.wav', shaped, wav.rate);
      return '$appDir/${file(name)}.m4a';
    }

    final reference = render('filter_reference', channels);
    final rendered = <String, String>{};
    String filtered(Kind kind, int freq, int slope) {
      final name = 'filter_${kind.name}_${freq}_${slope}db';
      return rendered[name] ??= render(name, [
        for (final c in channels)
          butterworth(c, wav.rate, kind, freq, slope ~/ 6),
      ]);
    }

    Map<String, dynamic> exercise({
      required String id,
      required int level,
      required String drill,
      required String path,
      required String question,
      required List<(String, String)> options,
      required String correct,
      required String explanation,
      required String tip,
      required Map<String, String> tags,
    }) => {
      'id': id,
      'module': module,
      'type': 'eq_band',
      'audio': {'source': 'asset', 'path': path},
      'reference': reference,
      'intro':
          'Compara el procesado con la referencia. El filtro ya está en el ejemplo.',
      'question': question,
      'options': [
        for (final (optionId, label) in options)
          {'id': optionId, 'label': label},
      ],
      'correct': correct,
      'difficulty': switch (level) {
        1 => 'beginner',
        2 => 'intermediate',
        _ => 'advanced',
      },
      'explanation': explanation,
      'tip': tip,
      'tags': {
        'skill': 'filter',
        'source': 'filter',
        'material': source.id,
        'level': '$level',
        'drill': drill,
        'ordered': 'true',
        ...tags,
      },
      'access': 'free',
    };

    final src = source.id.toUpperCase();

    // Level 1: high-pass or low-pass?
    for (final (kind, freq) in [
      (Kind.hpf, 200),
      (Kind.hpf, 400),
      (Kind.hpf, 800),
      (Kind.lpf, 1000),
      (Kind.lpf, 2000),
      (Kind.lpf, 4000),
    ]) {
      exercises.add(
        exercise(
          id: 'EQ_FILT_L1_${kind.name.toUpperCase()}_${freq}_$src',
          level: 1,
          drill: 'type',
          path: filtered(kind, freq, 12),
          question: '¿Qué filtro escuchas?',
          options: const [
            ('hpf', 'Pasa altos (recorta graves)'),
            ('lpf', 'Pasa bajos (recorta agudos)'),
          ],
          correct: kind.name,
          explanation: kind == Kind.hpf
              ? 'Es un pasa altos en ${hz(freq)}: recorta lo que está por debajo. '
                    'El sonido pierde peso y cuerpo, pero conserva el brillo.'
              : 'Es un pasa bajos en ${hz(freq)}: recorta lo que está por encima. '
                    'El sonido pierde brillo y aire, pero conserva el cuerpo.',
          tip:
              'Compara con la referencia y pregúntate qué se fue: '
              '¿el piso (los graves) o el techo (los agudos)?',
          tags: {'kind': kind.name, 'frequency': '$freq', 'slope': '12'},
        ),
      );
    }

    // Level 2: cutoff by octaves, 12 dB/oct.
    for (final kind in Kind.values) {
      final freqs = kind == Kind.hpf ? octaveHpf : octaveLpf;
      for (final freq in freqs) {
        exercises.add(
          exercise(
            id: 'EQ_FILT_L2_${kind.name.toUpperCase()}_${freq}_$src',
            level: 2,
            drill: 'cutoff_octave',
            path: filtered(kind, freq, 12),
            question:
                '${kindName(kind)} de 12 dB por octava. ¿Dónde está el corte?',
            options: [for (final f in freqs) ('f$f', hz(f))],
            correct: 'f$freq',
            explanation: cutoffExplanation(kind, freq),
            tip: kind == Kind.hpf
                ? 'Escucha el bajo y el bombo: cuanto más alto el corte, más se '
                      'adelgazan, hasta que también se afinan las voces y la caja.'
                : 'Escucha los platillos y las consonantes: cuanto más bajo el '
                      'corte, antes se apagan, hasta que todo suena detrás de una pared.',
            tags: {'kind': kind.name, 'frequency': '$freq', 'slope': '12'},
          ),
        );
      }
    }

    // Level 3: slope, cutoff fixed and stated.
    for (final kind in Kind.values) {
      final freq = kind == Kind.hpf ? slopeHpf : slopeLpf;
      for (final slope in slopes) {
        exercises.add(
          exercise(
            id: 'EQ_FILT_L3_SLOPE_${kind.name.toUpperCase()}_${slope}DB_$src',
            level: 3,
            drill: 'slope',
            path: filtered(kind, freq, slope),
            question: '${kindName(kind)} en ${hz(freq)}. ¿Qué pendiente tiene?',
            options: [for (final s in slopes) ('s$s', '$s dB/oct')],
            correct: 's$slope',
            explanation: slopeExplanation(slope),
            tip:
                'Fíjate en lo que queda justo más allá del corte: con 6 dB/oct '
                'aún se escucha bastante; con 24 dB/oct casi desaparece.',
            tags: {'kind': kind.name, 'frequency': '$freq', 'slope': '$slope'},
          ),
        );
      }
    }

    // Level 3: cutoff by third octaves, 24 dB/oct.
    for (final kind in Kind.values) {
      final freqs = kind == Kind.hpf ? thirdHpf : thirdLpf;
      for (final freq in freqs) {
        exercises.add(
          exercise(
            id: 'EQ_FILT_L3_THIRD_${kind.name.toUpperCase()}_${freq}_$src',
            level: 3,
            drill: 'cutoff_third',
            path: filtered(kind, freq, 24),
            question:
                '${kindName(kind)} de 24 dB por octava. ¿Dónde está el corte?',
            options: [for (final f in freqs) ('f$f', hz(f))],
            correct: 'f$freq',
            explanation: thirdExplanation(kind, freq),
            tip: kind == Kind.hpf
                ? 'Escucha cuánto cuerpo le queda al instrumento más grave que '
                      'aún suena: entre tercios cambia poco, pero cambia.'
                : 'Escucha cuánta definición le queda a la percusión: entre '
                      'tercios el brillo cambia poco, pero cambia.',
            tags: {'kind': kind.name, 'frequency': '$freq', 'slope': '24'},
          ),
        );
      }
    }
  }

  // Replace the previous filter exercises, keep everything else.
  final catalog =
      jsonDecode(File(catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final list = (catalog['exercises'] as List).cast<Map<String, dynamic>>();
  list.removeWhere((e) => (e['id'] as String).startsWith('EQ_FILT_'));
  list.addAll(exercises);
  File(catalogPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );

  report.forEach(stdout.writeln);
  stdout.writeln('Ejercicios de filtros: ${exercises.length}');
  stdout.writeln('Ahora corre: dart run tools/compress_audio.dart');
}

String kindName(Kind kind) => kind == Kind.hpf ? 'Pasa altos' : 'Pasa bajos';

String hz(int f) {
  if (f < 1000) return '$f Hz';
  final k = f / 1000;
  return '${k == k.roundToDouble() ? k.round() : k.toString().replaceAll('.', ',')} kHz';
}

String cutoffExplanation(Kind kind, int freq) {
  final lost = switch ((kind, freq)) {
    (Kind.hpf, 100) => 'los subgraves: el bombo y el bajo pierden profundidad',
    (Kind.hpf, 200) => 'los graves: el bajo queda delgado',
    (Kind.hpf, 400) => 'el cuerpo de los instrumentos: todo suena más liviano',
    (Kind.hpf, 800) => 'casi todo el cuerpo: suena como una radio pequeña',
    (Kind.lpf, 1000) => 'casi todo el brillo: suena como detrás de una pared',
    (Kind.lpf, 2000) => 'la presencia: las voces y la percusión se alejan',
    (Kind.lpf, 4000) => 'el brillo: los platillos pierden definición',
    (Kind.lpf, 8000) => 'solo el aire: el cambio es sutil, en los platillos',
    _ => 'esa zona',
  };
  final side = kind == Kind.hpf ? 'por debajo' : 'por encima';
  return 'El corte está en ${hz(freq)}. Se pierde lo que está $side, es decir, $lost.';
}

/// Third-octave cutoffs (24 dB/oct): what goes away at each band, and that
/// the neighbouring band sounds only slightly different.
String thirdExplanation(Kind kind, int freq) {
  final lost = switch ((kind, freq)) {
    (Kind.hpf, 160) => 'el retumbe del bombo y la base del bajo',
    (Kind.hpf, 200) => 'los graves del bajo, que queda más delgado',
    (Kind.hpf, 250) =>
      'el calor de los graves: el piano y las voces empiezan a adelgazarse',
    (Kind.hpf, 315) =>
      'parte del cuerpo: los instrumentos de registro medio suenan más livianos',
    (Kind.lpf, 2000) => 'la presencia: las voces y la percusión se alejan',
    (Kind.lpf, 2500) => 'parte de la presencia: las consonantes pierden filo',
    (Kind.lpf, 3150) => 'el filo del ataque: la percusión suena más suave',
    (Kind.lpf, 4000) => 'el brillo: los platillos pierden definición',
    _ => 'esa zona',
  };
  final side = kind == Kind.hpf ? 'por debajo' : 'por encima';
  return 'El corte está en ${hz(freq)}. Se pierde lo que está $side, es decir, '
      '$lost. Frente al tercio vecino el cambio es pequeño: es un ajuste de precisión.';
}

String slopeExplanation(int slope) => switch (slope) {
  6 =>
    'La pendiente es de 6 dB por octava: un corte muy suave que deja pasar '
        'bastante de lo que está más allá de la frecuencia.',
  12 =>
    'La pendiente es de 12 dB por octava: un corte moderado. Junto con la de '
        '18 dB, es de las más usadas en mezcla.',
  18 =>
    'La pendiente es de 18 dB por octava: un corte firme, ya se siente el '
        'límite.',
  _ =>
    'La pendiente es de 24 dB por octava: un corte casi de pared, lo que '
        'está más allá desaparece rápido.',
};

// ---------------------------------------------------------------- DSP

/// Butterworth high-pass or low-pass of [order] (1-4), as cascaded
/// sections. Each order adds 6 dB per octave.
Float64List butterworth(
  Float64List x,
  int rate,
  Kind kind,
  int freq,
  int order,
) {
  final sections = <List<double>>[];
  if (order.isOdd) sections.add(firstOrder(rate, kind, freq));
  // Q of each pole pair of the Butterworth prototype:
  // order 2 → 0.707; order 3 → 1.0 (+ first order); order 4 → 0.541, 1.307.
  for (var k = 0; k < order ~/ 2; k++) {
    final angle = order.isEven
        ? pi * (2 * k + 1) / (2 * order)
        : pi * (k + 1) / order;
    sections.add(biquad(rate, kind, freq, 1 / (2 * cos(angle))));
  }
  var y = x;
  for (final s in sections) {
    y = runSection(y, s);
  }
  return y;
}

/// RBJ cookbook biquad, normalized: [b0, b1, b2, a1, a2].
List<double> biquad(int rate, Kind kind, int freq, double q) {
  final w = 2 * pi * freq / rate;
  final alpha = sin(w) / (2 * q);
  final c = cos(w);
  final a0 = 1 + alpha;
  final b = kind == Kind.lpf
      ? [(1 - c) / 2, 1 - c, (1 - c) / 2]
      : [(1 + c) / 2, -(1 + c), (1 + c) / 2];
  return [b[0] / a0, b[1] / a0, b[2] / a0, -2 * c / a0, (1 - alpha) / a0];
}

/// First-order section by the bilinear transform, prewarped.
List<double> firstOrder(int rate, Kind kind, int freq) {
  final k = tan(pi * freq / rate);
  final a0 = 1 + k;
  final b = kind == Kind.lpf ? [k / a0, k / a0] : [1 / a0, -1 / a0];
  return [b[0], b[1], 0, (k - 1) / a0, 0];
}

Float64List runSection(Float64List x, List<double> s) {
  final y = Float64List(x.length);
  var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
  for (var i = 0; i < x.length; i++) {
    final v = s[0] * x[i] + s[1] * x1 + s[2] * x2 - s[3] * y1 - s[4] * y2;
    x2 = x1;
    x1 = x[i];
    y2 = y1;
    y1 = v;
    y[i] = v;
  }
  return y;
}

/// 10 ms fade-in and 600 ms fade-out (raised cosine).
Float64List fade(Float64List x, int rate) {
  final fin = (0.010 * rate).round();
  final fout = min((0.6 * rate).round(), x.length ~/ 2);
  for (var i = 0; i < fin && i < x.length; i++) {
    x[i] *= 0.5 - 0.5 * cos(pi * i / fin);
  }
  for (var i = 0; i < fout; i++) {
    x[x.length - 1 - i] *= 0.5 - 0.5 * cos(pi * i / fout);
  }
  return x;
}

/// BS.1770 integrated loudness for any sample rate (K-weighting, 400 ms
/// blocks with 75% overlap, absolute and relative gates).
double lufs(List<Float64List> channels, int rate) {
  List<double> shelf() {
    const f0 = 1681.974450955533, g = 3.999843853973347, q = 0.7071752369554196;
    final k = tan(pi * f0 / rate);
    final vh = pow(10, g / 20).toDouble();
    final vb = pow(vh, 0.4996667741545416).toDouble();
    final a0 = 1 + k / q + k * k;
    return [
      (vh + vb * k / q + k * k) / a0,
      2 * (k * k - vh) / a0,
      (vh - vb * k / q + k * k) / a0,
      2 * (k * k - 1) / a0,
      (1 - k / q + k * k) / a0,
    ];
  }

  List<double> highpass() {
    const f0 = 38.13547087602444, q = 0.5003270373238773;
    final k = tan(pi * f0 / rate);
    final a0 = 1 + k / q + k * k;
    return [1, -2, 1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0];
  }

  final weighted = [
    for (final c in channels) runSection(runSection(c, shelf()), highpass()),
  ];
  final block = (0.4 * rate).round();
  final hop = (0.1 * rate).round();
  final powers = <double>[];
  for (var start = 0; start + block <= weighted[0].length; start += hop) {
    var sum = 0.0;
    for (final c in weighted) {
      var s = 0.0;
      for (var i = start; i < start + block; i++) {
        s += c[i] * c[i];
      }
      sum += s / block;
    }
    powers.add(sum);
  }
  double loud(double p) => -0.691 + 10 * log(p) / ln10;
  final abs = powers.where((p) => loud(p) > -70).toList();
  final rel = loud(abs.reduce((a, b) => a + b) / abs.length) - 10;
  final gated = abs.where((p) => loud(p) > rel).toList();
  return loud(gated.reduce((a, b) => a + b) / gated.length);
}

// ---------------------------------------------------------------- WAV

class Wav {
  Wav(this.rate, this.channels);
  final int rate;
  final List<Float64List> channels;
}

/// Reads 16, 24 or 32-bit PCM and 32-bit float WAV, any channel count.
Wav readWav(String path) {
  final b = File(path).readAsBytesSync();
  final d = ByteData.sublistView(b);
  var format = 1, channels = 1, rate = 44100, bits = 16;
  for (var i = 12; i + 8 <= b.length;) {
    final id = String.fromCharCodes(b.sublist(i, i + 4));
    final size = d.getUint32(i + 4, Endian.little);
    if (id == 'fmt ') {
      format = d.getUint16(i + 8, Endian.little);
      channels = d.getUint16(i + 10, Endian.little);
      rate = d.getUint32(i + 12, Endian.little);
      bits = d.getUint16(i + 22, Endian.little);
      if (format == 0xFFFE) format = d.getUint16(i + 32, Endian.little);
    } else if (id == 'data') {
      final bytes = bits ~/ 8;
      final frames = min(size, b.length - i - 8) ~/ (bytes * channels);
      final out = [for (var c = 0; c < channels; c++) Float64List(frames)];
      var p = i + 8;
      for (var f = 0; f < frames; f++) {
        for (var c = 0; c < channels; c++) {
          out[c][f] = switch ((format, bits)) {
            (3, 32) => d.getFloat32(p, Endian.little),
            (_, 16) => d.getInt16(p, Endian.little) / 32768,
            (_, 24) =>
              ((b[p] | b[p + 1] << 8 | b[p + 2] << 16) << 8).toSigned(32) /
                  2147483648,
            (_, 32) => d.getInt32(p, Endian.little) / 2147483648,
            _ => throw FormatException('$path: formato no soportado'),
          };
          p += bytes;
        }
      }
      return Wav(rate, out);
    }
    i += 8 + size + (size.isOdd ? 1 : 0);
  }
  throw FormatException('$path: sin datos de audio');
}

/// 24-bit PCM with triangular dither.
void writeWav24(String path, List<Float64List> channels, int rate) {
  final frames = channels[0].length;
  final n = channels.length;
  final data = frames * n * 3;
  final d = ByteData(44 + data);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      d.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  d.setUint32(4, 36 + data, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, n, Endian.little);
  d.setUint32(24, rate, Endian.little);
  d.setUint32(28, rate * n * 3, Endian.little);
  d.setUint16(32, n * 3, Endian.little);
  d.setUint16(34, 24, Endian.little);
  tag(36, 'data');
  d.setUint32(40, data, Endian.little);
  final rng = Random(7);
  var p = 44;
  for (var f = 0; f < frames; f++) {
    for (var c = 0; c < n; c++) {
      final dither = (rng.nextDouble() - rng.nextDouble());
      final v = (channels[c][f] * 8388607 + dither).round().clamp(
        -8388608,
        8388607,
      );
      d.setUint8(p, v & 0xFF);
      d.setUint8(p + 1, (v >> 8) & 0xFF);
      d.setUint8(p + 2, (v >> 16) & 0xFF);
      p += 3;
    }
  }
  File(path).writeAsBytesSync(d.buffer.asUint8List());
}
