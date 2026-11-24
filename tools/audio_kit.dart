import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Shared audio helpers for the generators that build exercises from the
/// owner's recorded notes (generate_pitch_context.dart,
/// generate_intervals.dart): read the notes, retune them to exactly
/// 0 cents, mix, set loudness and write WAV files.

const keyTokens = [
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

class Instrument {
  Instrument(
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

  static Instrument load(
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
    return Instrument(
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
      final file = 'sample_${id}_${noteName(midi)}_$take.wav';
      final measured = cents[file] ?? (throw StateError('sin medición: $file'));
      var y = shiftCents(readMono('$dir/cortes/$file'), measured - detune);
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
    Mix mix,
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

String noteName(int midi) => '${keyTokens[midi % 12]}${midi ~/ 12 - 1}';

// --------------------------------------------------------------------- mix

const targetLufs = -25.0;
final peaks = <String, double>{};

class Mix {
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
    final scale = math.pow(10, (targetLufs - lufs(x)) / 20).toDouble();
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
    writeMono16(path, x);
  }
}

/// BS.1770 integrated loudness (48 kHz K-weighting, 400 ms blocks, gated).
double lufs(Float64List x) {
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

Float64List readMono(String path) {
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
Float64List shiftCents(Float64List x, double cents) {
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

void writeMono16(String path, Float64List x) {
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
