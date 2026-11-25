import 'dart:convert';
import 'dart:io';

/// Builds the app's compressed audio from the WAV masters.
///
/// Masters live in `audio_masters/`, with the same folders as `assets/`:
/// `audio_masters/tones/x.wav` becomes `assets/tones/x.m4a` (AAC). Only
/// folders declared in pubspec.yaml are converted, since the rest never
/// reach the app. A file is encoded again only when its master is newer.
///
/// It also rewrites every `.wav` path in assets/data/exercises.json to the
/// `.m4a` the app plays. Run it from the project root after any generator:
///
///   dart run tools/compress_audio.dart
///
/// Needs ffmpeg (installed with `winget install Gyan.FFmpeg`).
const mastersDir = 'audio_masters';
const assetsDir = 'assets';
const catalogPath = 'assets/data/exercises.json';

/// AAC bit rate per channel count. High enough to keep 16 kHz tones and
/// small EQ changes intact.
String bitrateFor(int channels) => channels == 1 ? '192k' : '256k';

Future<void> main(List<String> args) async {
  final ffmpeg = _findFfmpeg();
  if (ffmpeg == null) {
    stderr.writeln('No encuentro ffmpeg. Instálalo con: winget install Gyan.FFmpeg');
    exit(1);
  }

  final declared = _declaredFolders();
  final masters = Directory(mastersDir).existsSync()
      ? [
          for (final entity in Directory(mastersDir).listSync(recursive: true))
            if (entity is File && entity.path.toLowerCase().endsWith('.wav'))
              entity.path.replaceAll('\\', '/'),
        ]
      : <String>[];
  masters.sort();

  final jobs = <(String, String)>[];
  var skippedFolder = 0;
  var upToDate = 0;
  for (final master in masters) {
    final target = appPathOf(master);
    final folder = target.substring(0, target.lastIndexOf('/') + 1);
    if (!declared.contains(folder)) {
      skippedFolder++;
      continue;
    }
    final out = File(target);
    if (out.existsSync() &&
        !out.lastModifiedSync().isBefore(File(master).lastModifiedSync())) {
      upToDate++;
      continue;
    }
    jobs.add((master, target));
  }

  stdout.writeln(
    'Masters: ${masters.length}. Al día: $upToDate. '
    'Fuera de la app: $skippedFolder. Por convertir: ${jobs.length}.',
  );

  final failed = <String>[];
  var done = 0;
  const parallel = 4;
  for (var i = 0; i < jobs.length; i += parallel) {
    final batch = jobs.skip(i).take(parallel);
    await Future.wait([
      for (final (master, target) in batch)
        _encode(ffmpeg, master, target).then((ok) {
          if (!ok) failed.add(master);
          done++;
          if (done % 50 == 0 || done == jobs.length) {
            stdout.writeln('  $done/${jobs.length}');
          }
        }),
    ]);
  }

  final missing = _rewriteCatalog();

  if (failed.isNotEmpty) {
    stdout.writeln('No se pudieron convertir (${failed.length}):');
    for (final path in failed) {
      stdout.writeln('  - $path');
    }
  }
  if (missing.isNotEmpty) {
    stdout.writeln('El catálogo apunta a audios que no existen (${missing.length}):');
    for (final path in missing.take(30)) {
      stdout.writeln('  - $path');
    }
  }
  if (failed.isNotEmpty || missing.isNotEmpty) exit(1);
  stdout.writeln('Listo.');
}

/// `audio_masters/a/b.wav` or `assets/a/b.wav` → `assets/a/b.m4a`.
String appPathOf(String path) {
  var p = path.replaceAll('\\', '/');
  if (p.startsWith('$mastersDir/')) {
    p = '$assetsDir/${p.substring(mastersDir.length + 1)}';
  }
  return p.replaceFirst(RegExp(r'\.wav$', caseSensitive: false), '.m4a');
}

Future<bool> _encode(String ffmpeg, String master, String target) async {
  final channels = _channels(master);
  Directory(File(target).parent.path).createSync(recursive: true);
  final result = await Process.run(ffmpeg, [
    '-v', 'error',
    '-y',
    '-i', master,
    // Audio only: some WAVs carry a cover picture.
    '-vn',
    '-map_metadata', '-1',
    '-map_chapters', '-1',
    '-c:a', 'aac',
    '-b:a', bitrateFor(channels),
    '-cutoff', '20000',
    // Index at the start of the file, so playback begins while it loads.
    '-movflags', '+faststart',
    target,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln('$master: ${result.stderr}');
    // Never leave a half-written file: it would look up to date next time.
    final partial = File(target);
    if (partial.existsSync()) partial.deleteSync();
    return false;
  }
  return true;
}

/// Channel count from the WAV "fmt " chunk (1 when it cannot be read).
int _channels(String path) {
  final raf = File(path).openSync();
  try {
    final head = raf.readSync(4096);
    for (var i = 12; i + 10 < head.length;) {
      final id = String.fromCharCodes(head.sublist(i, i + 4));
      final size =
          head[i + 4] | head[i + 5] << 8 | head[i + 6] << 16 | head[i + 7] << 24;
      if (id == 'fmt ') return head[i + 10] | head[i + 11] << 8;
      i += 8 + size + (size.isOdd ? 1 : 0);
    }
    return 1;
  } finally {
    raf.closeSync();
  }
}

/// Rewrites `.wav` paths to `.m4a` and returns the ones that do not exist.
List<String> _rewriteCatalog() {
  final file = File(catalogPath);
  final catalog = jsonDecode(file.readAsStringSync());
  final missing = <String>{};
  var changed = 0;

  Object? walk(Object? node) {
    if (node is Map) {
      return {for (final e in node.entries) e.key: walk(e.value)};
    }
    if (node is List) return [for (final item in node) walk(item)];
    if (node is String &&
        (node.startsWith('$assetsDir/') || node.startsWith('$mastersDir/'))) {
      var path = node;
      if (path.toLowerCase().endsWith('.wav')) {
        path = appPathOf(path);
        changed++;
      }
      final lower = path.toLowerCase();
      if ((lower.endsWith('.m4a') || lower.endsWith('.mp4')) &&
          !File(path).existsSync()) {
        missing.add(path);
      }
      return path;
    }
    return node;
  }

  final updated = walk(catalog);
  if (changed > 0) {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(updated)}\n',
    );
  }
  stdout.writeln('Rutas del catálogo pasadas a .m4a: $changed');
  return missing.toList()..sort();
}

/// Asset folders listed in pubspec.yaml, e.g. `assets/tones/`.
Set<String> _declaredFolders() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  return {
    for (final line in lines)
      if (RegExp(r'^\s+-\s+(assets/\S*/)\s*$').firstMatch(line) case final m?)
        m.group(1)!,
  };
}

String? _findFfmpeg() {
  final local = Platform.environment['LOCALAPPDATA'];
  final candidates = [
    'ffmpeg',
    if (local != null) '$local\\Microsoft\\WinGet\\Links\\ffmpeg.exe',
  ];
  for (final candidate in candidates) {
    try {
      final result = Process.runSync(candidate, ['-version']);
      if (result.exitCode == 0) return candidate;
    } on ProcessException {
      continue;
    }
  }
  return null;
}
