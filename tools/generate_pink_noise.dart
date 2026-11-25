import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Generates the pink-noise EQ examples by code (no DAW involved):
///
/// * `pink_reference_01.wav`: clean pink noise (equal energy per octave,
///   20 Hz - 20 kHz), 2^19 samples at 48 kHz (10.9 s), mono, 24 bits.
/// * `freq_pink_{boost|cut}_{freq}_{g6|g9|c3|c6}_01.wav`: the same noise
///   with ONE peaking EQ band (RBJ bell, Q = 1.4, about one octave wide)
///   at 125 Hz - 8 kHz and +6, +9, -3 or -6 dB.
/// * `..._sweep_01.wav`: the same band moving in and out over clean noise
///   (clean → EQ → clean, 12.5 s), for the easier levels.
///
/// The band is applied in the frequency domain with the exact magnitude of
/// the bell, so the gain at the centre frequency is exact. Every file is
/// set to -20 LUFS (ITU-R BS.1770 K-weighting), so overall loudness never
/// gives the answer away. 30 ms fades at both ends avoid clicks.
///
/// Usage: dart run tools/generate_pink_noise.dart [outDir]
void main(List<String> args) {
  final outDir = args.isNotEmpty ? args[0] : 'audio_masters/eq/eq_pink_noise';
  Directory(outDir).createSync(recursive: true);
  const sr = 48000, n = 1 << 19, q = 1.4, targetLufs = -20.0;
  const frequencies = [125, 250, 500, 1000, 2000, 4000, 8000];
  const gains = [6, 9, -3, -6];

  // Pink spectrum: random phase, magnitude 1/sqrt(f), band-limited.
  final rng = math.Random(20261124);
  final re = Float64List(n), im = Float64List(n);
  for (var k = 1; k < n ~/ 2; k++) {
    final f = k * sr / n;
    if (f < 20 || f > 20000) continue;
    final mag = 1 / math.sqrt(f);
    final ph = rng.nextDouble() * 2 * math.pi;
    re[k] = mag * math.cos(ph);
    im[k] = mag * math.sin(ph);
    re[n - k] = re[k];
    im[n - k] = -im[k];
  }

  /// The noise through [gainAt], at -20 LUFS, one period (no fades).
  Float64List render(double Function(double f) gainAt) {
    final r = Float64List.fromList(re), i = Float64List.fromList(im);
    for (var k = 1; k < n ~/ 2; k++) {
      final g = gainAt(k * sr / n);
      r[k] *= g;
      i[k] *= g;
      r[n - k] *= g;
      i[n - k] *= g;
    }
    // loudness from the spectrum (exact for a circular signal)
    var ms = 0.0;
    for (var k = 1; k < n ~/ 2; k++) {
      final p = r[k] * r[k] + i[k] * i[k];
      ms += 2 * p * _kWeight(k * sr / n, sr);
    }
    ms /= n.toDouble() * n;
    final lufs = -0.691 + 10 * math.log(ms) / math.ln10;
    final scale = math.pow(10, (targetLufs - lufs) / 20).toDouble();
    _ifft(r, i);
    return Float64List.fromList([for (final v in r) v / n * scale]);
  }

  /// Writes [x] with 30 ms fades at both ends.
  void save(String name, Float64List x) {
    final fade = (0.03 * sr).round();
    var peak = 0.0;
    for (var s = 0; s < x.length; s++) {
      if (s < fade) x[s] *= s / fade;
      if (s >= x.length - fade) x[s] *= (x.length - 1 - s) / fade;
      peak = math.max(peak, x[s].abs());
    }
    if (peak >= 1) throw StateError('$name satura (pico ${_db(peak)} dBFS)');
    _writeMono24('$outDir/$name', x, sr);
    stdout.writeln('$name  pico ${_db(peak).toStringAsFixed(1)} dBFS');
  }

  final clean = render((_) => 1);
  save('pink_reference_01.wav', Float64List.fromList(clean));
  for (final f0 in frequencies) {
    for (final g in gains) {
      final kind = g > 0 ? 'boost' : 'cut';
      final token = g > 0 ? 'g$g' : 'c${-g}';
      final eq = render(
        (f) => _bellMagnitude(f, f0.toDouble(), g.toDouble(), q, sr),
      );
      save('freq_pink_${kind}_${f0}_${token}_01.wav', Float64List.fromList(eq));
      save(
        'freq_pink_${kind}_${f0}_${token}_sweep_01.wav',
        _sweep(clean, eq, sr),
      );
    }
  }
}

/// Clean → EQ → clean in one file, like an automated EQ band: 2 s clean,
/// 1.5 s fade in of the band, 5.5 s with the band, 1.5 s fade out, 2 s
/// clean (12.5 s). Both versions are the same noise at the same loudness
/// (the noise is periodic, so it repeats without a seam); the band comes in
/// by crossfading them with a raised-cosine curve.
Float64List _sweep(Float64List clean, Float64List eq, int sr) {
  const marks = [2.0, 3.5, 9.0, 10.5, 12.5];
  final length = (marks.last * sr).round();
  final x = Float64List(length);
  for (var s = 0; s < length; s++) {
    final t = s / sr;
    final double amount;
    if (t < marks[0] || t >= marks[3]) {
      amount = 0;
    } else if (t < marks[1]) {
      amount =
          0.5 -
          0.5 * math.cos(math.pi * (t - marks[0]) / (marks[1] - marks[0]));
    } else if (t < marks[2]) {
      amount = 1;
    } else {
      amount =
          0.5 +
          0.5 * math.cos(math.pi * (t - marks[2]) / (marks[3] - marks[2]));
    }
    final k = s % clean.length;
    x[s] = (1 - amount) * clean[k] + amount * eq[k];
  }
  return x;
}

/// |H(f)| of an RBJ peaking EQ.
double _bellMagnitude(double f, double f0, double gainDb, double q, int sr) {
  final a = math.pow(10, gainDb / 40).toDouble();
  final w0 = 2 * math.pi * f0 / sr, alpha = math.sin(w0) / (2 * q);
  final b = [1 + alpha * a, -2 * math.cos(w0), 1 - alpha * a];
  final c = [1 + alpha / a, -2 * math.cos(w0), 1 - alpha / a];
  return _biquadMag(b, c, 2 * math.pi * f / sr);
}

/// Power weighting of the BS.1770 K filter (48 kHz coefficients).
double _kWeight(double f, int sr) {
  final w = 2 * math.pi * f / sr;
  final shelf = _biquadMag(
    [1.53512485958697, -2.69169618940638, 1.19839281085285],
    [1.0, -1.69065929318241, 0.73248077421585],
    w,
  );
  final hp = _biquadMag(
    [1.0, -2.0, 1.0],
    [1.0, -1.99004745483398, 0.99007225036621],
    w,
  );
  return math.pow(shelf * hp, 2).toDouble();
}

double _biquadMag(List<double> b, List<double> a, double w) {
  double mag(List<double> c) {
    final re = c[0] + c[1] * math.cos(w) + c[2] * math.cos(2 * w);
    final im = -c[1] * math.sin(w) - c[2] * math.sin(2 * w);
    return math.sqrt(re * re + im * im);
  }

  return mag(b) / mag(a);
}

/// In-place inverse FFT without the 1/n factor (radix 2).
void _ifft(Float64List re, Float64List im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      var t = re[i];
      re[i] = re[j];
      re[j] = t;
      t = im[i];
      im[i] = im[j];
      im[j] = t;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = 2 * math.pi / len;
    final wr = math.cos(ang), wi = math.sin(ang);
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < len ~/ 2; k++) {
        final a = i + k, b = a + len ~/ 2;
        final vr = re[b] * cr - im[b] * ci, vi = re[b] * ci + im[b] * cr;
        re[b] = re[a] - vr;
        im[b] = im[a] - vi;
        re[a] += vr;
        im[a] += vi;
        final t = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = t;
      }
    }
  }
}

double _db(double v) => 20 * math.log(v) / math.ln10;

void _writeMono24(String path, Float64List x, int sr) {
  final bytes = x.length * 3;
  final d = ByteData(44 + bytes);
  void tag(int o, String s) {
    for (var i = 0; i < 4; i++) {
      d.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  d.setUint32(4, 36 + bytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, 1, Endian.little);
  d.setUint32(24, sr, Endian.little);
  d.setUint32(28, sr * 3, Endian.little);
  d.setUint16(32, 3, Endian.little);
  d.setUint16(34, 24, Endian.little);
  tag(36, 'data');
  d.setUint32(40, bytes, Endian.little);
  for (var i = 0; i < x.length; i++) {
    var v = (x[i] * 8388607).round().clamp(-8388608, 8388607);
    if (v < 0) v += 0x1000000;
    d.setUint8(44 + i * 3, v & 0xFF);
    d.setUint8(45 + i * 3, (v >> 8) & 0xFF);
    d.setUint8(46 + i * 3, (v >> 16) & 0xFF);
  }
  File(path).writeAsBytesSync(d.buffer.asUint8List());
}
