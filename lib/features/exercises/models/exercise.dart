import 'dart:math';

class ExerciseAudio {
  const ExerciseAudio({
    required this.source,
    required this.path,
  });

  final String source;
  final String path;

  bool get isAsset => source == 'asset';

  factory ExerciseAudio.fromJson(Map<String, dynamic> json) {
    final source = _requireString(json['source'], 'audio.source');
    if (source != 'asset' && source != 'url') {
      throw const FormatException('audio.source debe ser "asset" o "url".');
    }
    return ExerciseAudio(
      source: source,
      path: _requireString(json['path'], 'audio.path'),
    );
  }
}

class ExerciseOption {
  const ExerciseOption({
    required this.id,
    required this.label,
    this.path,
  });

  final String id;
  final String label;
  final String? path;

  factory ExerciseOption.fromJson(Map<String, dynamic> json) {
    final path = json['path'];
    if (path != null && path is! String) {
      throw const FormatException('options.path debe ser texto.');
    }
    return ExerciseOption(
      id: _requireString(json['id'], 'options.id'),
      label: _requireString(json['label'], 'options.label'),
      path: path as String?,
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.module,
    required this.type,
    required this.audio,
    required this.question,
    required this.options,
    this.maxOptions,
    required this.correct,
    required this.difficulty,
    required this.explanation,
    this.explanationIncorrect,
    this.introSubtitle,
    required this.tags,
    required this.access,
  });

  final String id;
  final String module;
  final String type;
  final ExerciseAudio audio;
  final String question;
  final List<ExerciseOption> options;
  final int? maxOptions;
  final String correct;
  final String difficulty;
  final String explanation;
  final String? explanationIncorrect;
  final String? introSubtitle;
  final Map<String, String> tags;
  final String access;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final id = _requireString(json['id'], 'id');
    try {
      return _fromJson(id, json);
    } on FormatException catch (error) {
      throw FormatException('${error.message} (ejercicio $id)');
    }
  }

  static Exercise _fromJson(String id, Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      throw const FormatException('options debe ser una lista con opciones.');
    }

    final options = <ExerciseOption>[];
    final optionIds = <String>{};
    for (final raw in rawOptions) {
      if (raw is! Map) {
        throw const FormatException('Cada opción debe ser un objeto.');
      }
      final option = ExerciseOption.fromJson(Map<String, dynamic>.from(raw));
      if (!optionIds.add(option.id)) {
        throw FormatException('Opción duplicada "${option.id}".');
      }
      options.add(option);
    }

    final correct = _requireString(json['correct'], 'correct');
    if (!optionIds.contains(correct)) {
      throw FormatException('correct "$correct" no coincide con ninguna opción.');
    }

    final maxOptions = _optionalInt(json['maxOptions'], 'maxOptions');
    if (maxOptions != null && maxOptions < 1) {
      throw const FormatException('maxOptions debe ser mayor que cero.');
    }

    return Exercise(
      id: id,
      module: _requireString(json['module'], 'module'),
      type: _requireString(json['type'], 'type'),
      audio: _audioFrom(json['audio']),
      question: _requireString(json['question'], 'question'),
      options: List<ExerciseOption>.unmodifiable(options),
      maxOptions: maxOptions,
      correct: correct,
      difficulty: _requireString(json['difficulty'], 'difficulty'),
      explanation: _requireString(json['explanation'], 'explanation'),
      explanationIncorrect: _optionalString(json['explanationIncorrect']),
      introSubtitle: _optionalString(json['introSubtitle']),
      tags: _tagsFrom(json['tags']),
      access: _requireString(json['access'], 'access'),
    );
  }

  /// Options shown for this exercise.
  ///
  /// Without [maxOptions], the stored order is preserved so an A/B compare can
  /// randomize the slots itself. With [maxOptions], the correct option is kept
  /// and random distractors fill the remaining slots.
  List<ExerciseOption> present({Random? random}) {
    final limit = maxOptions;
    if (limit == null || limit >= options.length) {
      return List<ExerciseOption>.unmodifiable(options);
    }

    final rng = random ?? Random();
    final correctIndex = options.indexWhere((option) => option.id == correct);
    if (correctIndex == -1) {
      throw StateError(
        'El ejercicio $id no contiene la opción correcta "$correct".',
      );
    }
    final correctOption = options[correctIndex];

    final distractors = [
      for (final option in options)
        if (option.id != correct) option,
    ]..shuffle(rng);
    final selected = <ExerciseOption>[
      correctOption,
      ...distractors.take(limit - 1),
    ]..shuffle(rng);
    return List<ExerciseOption>.unmodifiable(selected);
  }

  Iterable<String> get assetPaths sync* {
    if (audio.isAsset) yield audio.path;
    for (final option in options) {
      final path = option.path;
      if (path == null || path.isEmpty || _isRemote(path)) continue;
      yield path;
    }
  }
}

ExerciseAudio _audioFrom(Object? raw) {
  if (raw is! Map) {
    throw const FormatException('audio debe ser un objeto.');
  }
  return ExerciseAudio.fromJson(Map<String, dynamic>.from(raw));
}

Map<String, String> _tagsFrom(Object? raw) {
  if (raw is! Map) {
    throw const FormatException('tags debe ser un objeto.');
  }
  final tags = <String, String>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! String) {
      throw const FormatException('tags solo admite texto.');
    }
    tags[key] = value;
  }
  return Map<String, String>.unmodifiable(tags);
}

String _requireString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field es obligatorio.');
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('El texto opcional debe ser texto.');
  }
  return value;
}

int? _optionalInt(Object? value, String field) {
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('$field debe ser un entero.');
  }
  return value;
}

bool _isRemote(String path) {
  return path.startsWith('http://') || path.startsWith('https://');
}
