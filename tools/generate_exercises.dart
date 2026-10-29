// One-shot generator. Re-running replaces chord_quality and interval_quality
// and leaves every other exercise, including the five EQ entries, unchanged.
import 'dart:convert';
import 'dart:io';

const _generatedTypes = {'chord_quality', 'interval_quality'};

const _folders = [
  'chords_min_maj',
  'chords_maj7_min7_dom7',
  'triadas_inversiones',
  'inversiones_chords',
  'intervalos_ascendentes',
  'intervalos_descendentes',
  'intervalos_armonicos',
];

const _triadOptions = [
  {'id': 'maj', 'label': 'Mayor'},
  {'id': 'min', 'label': 'Menor'},
];

const _seventhOptions = [
  {'id': 'maj7', 'label': 'Mayor 7'},
  {'id': 'dom7', 'label': 'Dominante 7'},
  {'id': 'min7', 'label': 'Menor 7'},
];

const _intervalOptions = [
  {'id': 'min2', 'label': '2da menor'},
  {'id': 'maj2', 'label': '2da mayor'},
  {'id': 'min3', 'label': '3ra menor'},
  {'id': 'maj3', 'label': '3ra mayor'},
  {'id': 'perf4', 'label': '4ta justa'},
  {'id': 'tritone', 'label': 'tritono'},
  {'id': 'perf5', 'label': '5ta justa'},
  {'id': 'min6', 'label': '6ta menor'},
  {'id': 'maj6', 'label': '6ta mayor'},
  {'id': 'min7', 'label': '7ma menor'},
  {'id': 'maj7', 'label': '7ma mayor'},
  {'id': 'perf8', 'label': 'octava'},
];

const _pitchNames = {
  'c': 'Do',
  'csharp': 'Do sostenido',
  'd': 'Re',
  'dsharp': 'Re sostenido',
  'e': 'Mi',
  'f': 'Fa',
  'fsharp': 'Fa sostenido',
  'g': 'Sol',
  'gsharp': 'Sol sostenido',
  'a': 'La',
  'asharp': 'La sostenido',
  'b': 'Si',
};

final _chordPattern = RegExp(
  r'^chord_(maj7|min7|dom7|maj|min)(?:_(inv1|inv2|inv3))?_([a-g](?:sharp)?[0-9]+)_([0-9]+)\.wav$',
);

final _intervalPattern = RegExp(
  r'^interval_(min2|maj2|min3|maj3|perf4|tritone|perf5|min6|maj6|min7|maj7|perf8)_(asc|desc|harm)_([a-g](?:sharp)?[0-9]+)_([0-9]+)\.wav$',
);

void main() {
  final root = _projectRoot();
  final jsonFile = File(_join([root.path, 'assets', 'data', 'exercises.json']));
  final decoded = jsonDecode(jsonFile.readAsStringSync());
  if (decoded is! Map || decoded['exercises'] is! List) {
    stderr.writeln('exercises.json debe contener la lista "exercises".');
    exit(1);
  }

  final existing = [
    for (final item in decoded['exercises'] as List)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
  final kept = [
    for (final exercise in existing)
      if (!_generatedTypes.contains(exercise['type'])) exercise,
  ];
  final keptIds = {for (final exercise in kept) exercise['id'].toString()};

  final skipped = <String>[];
  final generated = <Map<String, dynamic>>[];
  final seenIds = <String>{...keptIds};

  for (final folder in _folders) {
    final dir = Directory(_join([root.path, 'assets', 'musical', folder]));
    if (!dir.existsSync()) {
      skipped.add('$folder/ — la carpeta no existe');
      continue;
    }
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final exercise = _exerciseFor(folder, name);
      if (exercise == null) {
        skipped.add('$folder/$name — no coincide con el patrón de esa carpeta');
        continue;
      }
      final id = exercise['id']! as String;
      if (!seenIds.add(id)) {
        skipped.add('$folder/$name — id duplicado "$id"');
        continue;
      }
      generated.add(exercise);
    }
  }

  _rejectRepeatedCopy(generated);

  generated.sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  final encoder = const JsonEncoder.withIndent('  ');
  jsonFile.writeAsStringSync(
    '${encoder.convert({'exercises': [...kept, ...generated]})}\n',
  );

  final chordCount = generated.where((e) => e['type'] == 'chord_quality').length;
  final intervalCount =
      generated.where((e) => e['type'] == 'interval_quality').length;
  stdout.writeln('Conservados: ${kept.length}');
  stdout.writeln('chord_quality: $chordCount');
  stdout.writeln('interval_quality: $intervalCount');
  for (final type in ['chord_quality', 'interval_quality']) {
    final byDifficulty = <String, int>{};
    for (final exercise in generated.where((e) => e['type'] == type)) {
      final difficulty = exercise['difficulty']! as String;
      byDifficulty[difficulty] = (byDifficulty[difficulty] ?? 0) + 1;
    }
    final parts = [
      for (final entry in byDifficulty.entries) '${entry.key}: ${entry.value}',
    ];
    stdout.writeln('  $type por dificultad — ${parts.join(', ')}');
  }
  stdout.writeln('Omitidos: ${skipped.length}');
  for (final line in skipped) {
    stdout.writeln('  $line');
  }
}

Map<String, dynamic>? _exerciseFor(String folder, String name) {
  final chord = _chordPattern.firstMatch(name);
  if (chord != null) {
    final quality = chord.group(1)!;
    final inversion = chord.group(2);
    final root = chord.group(3)!;
    if (!_chordFolderAccepts(folder, quality, inversion)) return null;
    final position = inversion ?? 'root';
    final inverted = position != 'root';
    final copy = _chords[quality]!;
    return {
      'id': name.substring(0, name.length - 4),
      'module': 'entrenamientoMusical',
      'type': 'chord_quality',
      'audio': {
        'source': 'asset',
        'path': 'assets/musical/$folder/$name',
      },
      'intro': inverted ? copy.invertedIntro : copy.intro,
      'question': quality == 'maj' || quality == 'min'
          ? '¿Este acorde es mayor o menor?'
          : '¿Qué acorde con séptima escuchas?',
      'options': quality == 'maj' || quality == 'min'
          ? _triadOptions
          : _seventhOptions,
      'correct': quality,
      'difficulty': inverted ? 'intermediate' : 'beginner',
      'explanation': _chordExplanation(quality, root, position),
      'tip': inverted ? copy.invertedTip : copy.tip,
      'tags': {
        'root': root,
        'inversion': position,
        'voicing': inverted ? 'bass_inverted' : 'root',
      },
      'access': 'free',
    };
  }

  final interval = _intervalPattern.firstMatch(name);
  if (interval != null) {
    final kind = interval.group(1)!;
    final mode = interval.group(2)!;
    final startNote = interval.group(3)!;
    if (_modeForFolder(folder) != mode) return null;
    final copy = _intervals[kind]!;
    return {
      'id': name.substring(0, name.length - 4),
      'module': 'entrenamientoMusical',
      'type': 'interval_quality',
      'audio': {
        'source': 'asset',
        'path': 'assets/musical/$folder/$name',
      },
      'intro': copy.intro,
      'question': '¿Qué intervalo escuchas?',
      'options': _intervalOptions,
      'maxOptions': 4,
      'correct': kind,
      'difficulty': switch (mode) {
        'asc' => 'beginner',
        'desc' => 'intermediate',
        'harm' => 'advanced',
        _ => throw StateError('Modo desconocido: $mode'),
      },
      'explanation': _intervalExplanation(kind, mode),
      'tip': copy.tipFor(mode),
      'tags': {
        'mode': mode,
        'startNote': startNote,
      },
      'access': 'free',
    };
  }

  return null;
}

bool _chordFolderAccepts(String folder, String quality, String? inversion) {
  final triad = quality == 'maj' || quality == 'min';
  final seventh = quality == 'maj7' || quality == 'dom7' || quality == 'min7';
  return switch (folder) {
    'chords_min_maj' => triad && inversion == null,
    'chords_maj7_min7_dom7' => seventh && inversion == null,
    'triadas_inversiones' =>
      triad && (inversion == 'inv1' || inversion == 'inv2'),
    'inversiones_chords' => seventh && inversion != null,
    _ => false,
  };
}

String? _modeForFolder(String folder) {
  return switch (folder) {
    'intervalos_ascendentes' => 'asc',
    'intervalos_descendentes' => 'desc',
    'intervalos_armonicos' => 'harm',
    _ => null,
  };
}

String _chordExplanation(String quality, String root, String inversion) {
  final note = _pitchName(root);
  final kind = switch (quality) {
    'maj' =>
      'Es mayor sobre $note: la tercera está a dos tonos de la fundamental.',
    'min' =>
      'Es menor sobre $note: la tercera está a un tono y medio y el color es más oscuro.',
    'maj7' =>
      'Es mayor 7 sobre $note: un acorde mayor más una séptima a un semitono de la octava.',
    'dom7' =>
      'Es dominante 7 sobre $note: la tercera mayor y la séptima menor forman un tritono.',
    'min7' =>
      'Es menor 7 sobre $note: tercera menor y séptima menor, sin el tritono del dominante.',
    _ => throw StateError('Calidad desconocida: $quality'),
  };
  final bass = switch (inversion) {
    'root' => 'La fundamental suena en el bajo.',
    'inv1' => 'Suena en primera inversión: la tercera está en el bajo.',
    'inv2' => 'Suena en segunda inversión: la quinta está en el bajo.',
    'inv3' => 'Suena en tercera inversión: la séptima está en el bajo.',
    _ => throw StateError('Inversión desconocida: $inversion'),
  };
  return '$kind $bass';
}

String _intervalExplanation(String kind, String mode) {
  final noun = switch (kind) {
    'tritone' => 'un tritono',
    _ => 'una ${_intervalNouns[kind]}',
  };
  final fact = _intervalFacts[kind]!;
  final motion = switch (mode) {
    'asc' => 'La segunda nota está más aguda.',
    'desc' => 'La segunda nota está más grave.',
    'harm' => 'Las dos notas suenan a la vez.',
    _ => throw StateError('Modo desconocido: $mode'),
  };
  return 'Es $noun. $fact $motion';
}

String _pitchName(String token) {
  final match = RegExp(r'^([a-g](?:sharp)?)[0-9]+$').firstMatch(token);
  final name = match == null ? null : _pitchNames[match.group(1)];
  if (name == null) {
    throw StateError('Nota no reconocida: $token');
  }
  return name;
}

void _rejectRepeatedCopy(List<Map<String, dynamic>> exercises) {
  final introOwner = <String, String>{};
  final tipOwner = <String, String>{};
  for (final exercise in exercises) {
    final tags = exercise['tags']! as Map;
    final owner = '${exercise['type']}:${exercise['correct']}';
    final tipIdentity = exercise['type'] == 'interval_quality'
        ? '$owner:${tags['mode']}'
        : '$owner:${tags['voicing']}';
    final intro = exercise['intro']! as String;
    final tip = exercise['tip']! as String;
    final previousIntro = introOwner[intro];
    if (previousIntro != null && previousIntro != owner) {
      throw StateError('intro de "$owner" repite el de "$previousIntro"');
    }
    final previousTip = tipOwner[tip];
    if (previousTip != null && previousTip != tipIdentity) {
      throw StateError('tip de "$tipIdentity" repite el de "$previousTip"');
    }
    introOwner[intro] = owner;
    tipOwner[tip] = tipIdentity;
  }
}

Directory _projectRoot() {
  final candidates = [
    Directory.current,
    File(Platform.script.toFilePath()).parent.parent,
  ];
  for (final dir in candidates) {
    final pubspec = File(_join([dir.path, 'pubspec.yaml']));
    final jsonFile = File(_join([dir.path, 'assets', 'data', 'exercises.json']));
    if (pubspec.existsSync() && jsonFile.existsSync()) return dir;
  }
  stderr.writeln('Ejecuta el script desde la raíz del proyecto ear_trainer.');
  exit(1);
}

String _join(List<String> parts) => parts.join(Platform.pathSeparator);

class _ChordCopy {
  const _ChordCopy({
    required this.intro,
    required this.invertedIntro,
    required this.tip,
    required this.invertedTip,
  });

  final String intro;
  final String invertedIntro;
  final String tip;
  final String invertedTip;
}

class _IntervalCopy {
  const _IntervalCopy({
    required this.intro,
    required this.ascTip,
    required this.descTip,
    required this.harmTip,
  });

  final String intro;
  final String ascTip;
  final String descTip;
  final String harmTip;

  String tipFor(String mode) {
    return switch (mode) {
      'asc' => ascTip,
      'desc' => descTip,
      'harm' => harmTip,
      _ => throw StateError('Modo desconocido: $mode'),
    };
  }
}

const _chords = {
  'maj': _ChordCopy(
    intro:
        'Entrenas el acorde mayor: tres notas con una tercera grande en el centro. Es el color luminoso y estable que te sirve de referencia para reconocer casi todo lo demás.',
    invertedIntro:
        'Entrenas el acorde mayor cuando la fundamental no está en el bajo. El color sigue siendo luminoso; el trabajo es no dejarte engañar por la nota más grave.',
    tip:
        'Fíjate en la tercera, dos tonos por encima de la fundamental. Si brilla y el acorde se siente abierto, es mayor.',
    invertedTip:
        'La tercera mayor sigue a dos tonos de la fundamental, aunque ya no suene encima del bajo. Si el color es luminoso, es mayor.',
  ),
  'min': _ChordCopy(
    intro:
        'Entrenas el acorde menor. También son tres notas, pero la del medio está un semitono más baja que en el mayor, y por eso suena más oscuro y menos conclusivo.',
    invertedIntro:
        'Entrenas el acorde menor con el bajo cambiado. La nota grave ya no nombra el acorde: hay que encontrar la tercera menor, que lo oscurece.',
    tip:
        'La pista es la tercera, a un tono y medio de la fundamental. Queda más baja que en el mayor y el color se apaga.',
    invertedTip:
        'Aunque el bajo sea otra nota, la tercera está un semitono más baja que la del mayor. Ese oscurecimiento es lo que lo hace menor.',
  ),
  'maj7': _ChordCopy(
    intro:
        'Entrenas el acorde mayor 7. Nace de un mayor y suma la séptima mayor, a un semitono de la octava. Suena amplio y suave, muy usado en jazz, y no empuja a resolver.',
    invertedIntro:
        'Entrenas el mayor 7 en inversión. Cambia la nota del bajo, no el color: sigue siendo un mayor con una séptima brillante pegada a la octava.',
    tip:
        'Busca la nota que casi llega a la octava y se queda a un semitono. Brilla, y no tiene el roce áspero del dominante.',
    invertedTip:
        'Ignora qué nota quedó abajo. La séptima mayor sigue a un semitono de la octava, suave y sin el tritono del dominante.',
  ),
  'dom7': _ChordCopy(
    intro:
        'Entrenas el acorde dominante 7. También parte de un mayor, pero su séptima es menor. Entre esa séptima y la tercera aparece un tritono, la tensión que suele pedir ir hacia la tónica.',
    invertedIntro:
        'Entrenas el dominante 7 aunque el bajo no sea la fundamental. La inversión mueve el grave; la tensión que tienes que oír sigue siendo el tritono.',
    tip:
        'Escucha el choque entre la tercera mayor y la séptima menor. Ese tritono suena inestable, como si el acorde quisiera moverse.',
    invertedTip:
        'El bajo cambió, pero el tritono entre la tercera mayor y la séptima menor sigue ahí. Esa tensión es la del dominante.',
  ),
  'min7': _ChordCopy(
    intro:
        'Entrenas el acorde menor 7. Es un menor con una séptima menor añadida. Suena redondo y relajado: tiene séptima, pero no el tritono que vuelve urgente al dominante.',
    invertedIntro:
        'Entrenas el menor 7 con el bajo invertido. No lo confundas con un dominante: su tercera es menor y su séptima no choca contra ella.',
    tip:
        'Hay una tercera menor y, arriba, una séptima a un tono de la octava. No aparece el tritono: suena oscuro y blando, no urgente.',
    invertedTip:
        'No busques el choque del dominante. La tercera es menor y la séptima queda a un tono de la octava, aunque el bajo sea otra nota.',
  ),
};

const _intervalNouns = {
  'min2': 'segunda menor',
  'maj2': 'segunda mayor',
  'min3': 'tercera menor',
  'maj3': 'tercera mayor',
  'perf4': 'cuarta justa',
  'tritone': 'tritono',
  'perf5': 'quinta justa',
  'min6': 'sexta menor',
  'maj6': 'sexta mayor',
  'min7': 'séptima menor',
  'maj7': 'séptima mayor',
  'perf8': 'octava',
};

const _intervalFacts = {
  'min2': 'Mide un semitono, la distancia más pequeña.',
  'maj2': 'Mide un tono entero, dos semitonos.',
  'min3': 'Mide tres semitonos y da el color del acorde menor.',
  'maj3': 'Mide cuatro semitonos y da el brillo del acorde mayor.',
  'perf4': 'Mide cinco semitonos y no es mayor ni menor.',
  'tritone': 'Mide seis semitonos y parte la octava por la mitad.',
  'perf5': 'Mide siete semitonos y es una consonancia hueca y estable.',
  'min6': 'Mide ocho semitonos y suena ancha, con un dejo nostálgico.',
  'maj6': 'Mide nueve semitonos y suena abierta y luminosa.',
  'min7': 'Mide diez semitonos y queda a un tono de la octava.',
  'maj7': 'Mide once semitonos y queda a un semitono de la octava.',
  'perf8': 'Mide doce semitonos: la misma nota en otro registro.',
};

const _intervals = {
  'min2': _IntervalCopy(
    intro:
        'La segunda menor es un semitono, el salto entre dos teclas vecinas. Reconocerla te da la unidad con la que se miden todos los demás intervalos.',
    ascTip:
        'La segunda nota sube apenas un semitono. El roce es inmediato, como si las dos notas no cupieran.',
    descTip:
        'La segunda nota baja un semitono. El descenso es mínimo: casi la misma altura, solo un poco más grave.',
    harmTip:
        'Suenan juntas, separadas por un solo semitono. El choque es áspero y muy cerrado.',
  ),
  'maj2': _IntervalCopy(
    intro:
        'La segunda mayor es un tono entero, dos semitonos. Es el paso de vecino más habitual de una escala y suena cercano, ya sin el roce tan cerrado de la segunda menor.',
    ascTip:
        'Sube un tono, no un semitono. Hay un hueco claro y la tensión es suave, de paso entre vecinos.',
    descTip:
        'Baja un tono entero. Se siente un paso completo, más holgado que el semitono de la segunda menor.',
    harmTip:
        'Suenan a la vez con un tono de por medio. Hay roce, pero más abierto que el de dos teclas vecinas.',
  ),
  'min3': _IntervalCopy(
    intro:
        'La tercera menor abarca tres semitonos. Es la distancia que vuelve menor a un acorde: si la reconoces, ya puedes separar un color oscuro de uno brillante.',
    ascTip:
        'La nota alta queda a un tono y medio. Comparada con una tercera mayor, llega un semitono antes y suena más oscura.',
    descTip:
        'El salto hacia abajo es de tres semitonos. El color es el del acorde menor, más sombrío que una tercera mayor.',
    harmTip:
        'Las dos notas forman a la vez una tercera menor. Ese intervalo es el centro sonoro del acorde menor.',
  ),
  'maj3': _IntervalCopy(
    intro:
        'La tercera mayor abarca cuatro semitonos, dos tonos. Es el intervalo que da al acorde mayor su brillo y su sensación de reposo.',
    ascTip:
        'Sube dos tonos justos. Es el salto que abre un acorde mayor: luminoso y estable.',
    descTip:
        'Baja dos tonos. La nota de llegada sigue sonando mayor, brillante y no apagada.',
    harmTip:
        'Suenan juntas a dos tonos de distancia. El resultado es consonante y claro, la tercera del acorde mayor.',
  ),
  'perf4': _IntervalCopy(
    intro:
        'La cuarta justa son cinco semitonos. No es mayor ni menor: suena abierta y un poco suspendida, como si todavía no se hubiera apoyado en una tercera.',
    ascTip:
        'Sube cinco semitonos. La llegada es limpia, pero hueca: no tiene el color de una tercera.',
    descTip:
        'Baja una cuarta justa. El salto es amplio y abierto, ni triste como el menor ni brillante como el mayor.',
    harmTip:
        'Juntas suenan limpias y huecas. No hay una tercera que las vuelva mayores o menores: el intervalo queda abierto.',
  ),
  'tritone': _IntervalCopy(
    intro:
        'El tritono parte la octava por la mitad: seis semitonos. Es el intervalo más inestable y el mismo choque que empuja al acorde dominante a resolver.',
    ascTip:
        'Sube seis semitonos, media octava. Ni la cuarta ni la quinta terminan de asentarse: la nota queda en el medio y pide moverse.',
    descTip:
        'Baja exactamente media octava. La caída no encuentra apoyo consonante: sigue tensa en los dos extremos.',
    harmTip:
        'Suenan a la vez y el choque es muy áspero. Es el mismo tritono que hay entre la tercera y la séptima del dominante.',
  ),
  'perf5': _IntervalCopy(
    intro:
        'La quinta justa son siete semitonos. Junto con la octava, es de las consonancias más firmes: hueca, estable y sin color mayor ni menor.',
    ascTip:
        'Sube siete semitonos. La nota alta suena hueca y sólida, un semitono por encima de donde estaría el tritono.',
    descTip:
        'Baja una quinta justa. El salto se siente amplio y asentado, sin una tensión que haya que resolver.',
    harmTip:
        'Suenan juntas y casi se funden. No hay choque: es la quinta limpia del acorde.',
  ),
  'min6': _IntervalCopy(
    intro:
        'La sexta menor son ocho semitonos. Suena ancha y algo nostálgica, y es la inversión de la tercera mayor: la misma familia de notas, escuchada al revés.',
    ascTip:
        'Sube ocho semitonos, uno más que la quinta. El salto ya es ancho y el color queda dulce, no del todo luminoso.',
    descTip:
        'La caída cubre ocho semitonos. Es grande y algo melancólica, un semitono más estrecha que la sexta mayor.',
    harmTip:
        'Juntas ocupan el lugar de una tercera mayor invertida. Suena suave, con un dejo nostálgico.',
  ),
  'maj6': _IntervalCopy(
    intro:
        'La sexta mayor son nueve semitonos. Suena abierta y luminosa, y es la inversión de la tercera menor.',
    ascTip:
        'Sube nueve semitonos: un tono por encima de la quinta y un semitono más que la sexta menor. El salto se oye despejado.',
    descTip:
        'Baja nueve semitonos. Sigue sonando mayor: brillante, no nostálgica.',
    harmTip:
        'Es una tercera menor dada vuelta. Suena consonante y clara, más luminosa que la sexta menor.',
  ),
  'min7': _IntervalCopy(
    intro:
        'La séptima menor son diez semitonos, a un tono de la octava. Es la séptima del dominante y del menor 7: amplia, y con tendencia a bajar.',
    ascTip:
        'Sube diez semitonos y se queda a un tono de la octava. No llega arriba del todo: esa distancia es lo que se escucha.',
    descTip:
        'Baja diez semitonos. La nota grave queda a un tono de la octava inferior, amplia y un poco inestable.',
    harmTip:
        'Suenan a un tono de la octava. El intervalo es ancho y blando, el de la séptima del acorde dominante.',
  ),
  'maj7': _IntervalCopy(
    intro:
        'La séptima mayor son once semitonos. Se queda a un semitono de la octava, como la nota sensible que quiere resolver hacia arriba.',
    ascTip:
        'Casi alcanza la octava y se detiene un semitono antes. Ese casi, brillante y cercano, es la séptima mayor.',
    descTip:
        'Casi cae una octava, pero se queda un semitono por encima de ella. Las dos notas quedan vecinas de octava.',
    harmTip:
        'Están a un semitono de formar una octava. El roce es agudo y luminoso, más cerrado que el tono entero de la séptima menor.',
  ),
  'perf8': _IntervalCopy(
    intro:
        'La octava son doce semitonos: la misma nota, más aguda o más grave. Es el marco donde caben los demás intervalos y la consonancia que más fácilmente se fusiona.',
    ascTip:
        'La segunda nota repite el mismo nombre y suena el doble de aguda. Al cantarla, la voz siente que llegó a la misma nota.',
    descTip:
        'Baja hasta la misma nota, una octava más grave. No cambia de nombre, solo de registro.',
    harmTip:
        'Suenan juntas y se fusionan: es la misma nota en dos alturas. No hay roce ni color mayor o menor.',
  ),
};
