import 'dart:convert';

import 'package:flutter/services.dart';

class TrainingContextVariant {
  const TrainingContextVariant({
    required this.intro,
    required this.skills,
    required this.closing,
  });

  final String intro;
  final List<String> skills;
  final String closing;

  factory TrainingContextVariant.fromJson(Map<String, dynamic> json) {
    final skills = json['skills'];
    return TrainingContextVariant(
      intro: json['intro'] as String? ?? '',
      skills: skills is List
          ? [for (final item in skills) if (item is String) item]
          : const [],
      closing: json['closing'] as String? ?? '',
    );
  }
}

class TrainingContextCopy {
  const TrainingContextCopy({
    required this.title,
    required this.full,
    required this.short,
  });

  final String title;
  final TrainingContextVariant full;
  final TrainingContextVariant short;

  factory TrainingContextCopy.fromJson(Map<String, dynamic> json) {
    return TrainingContextCopy(
      title: json['title'] as String? ?? '',
      full: TrainingContextVariant.fromJson(_map(json['full'])),
      short: TrainingContextVariant.fromJson(_map(json['short'])),
    );
  }
}

class TrainingContextLibrary {
  TrainingContextLibrary._();

  static const assetPath = 'assets/data/training_context.json';
  static Map<String, TrainingContextCopy>? _copies;

  static Future<TrainingContextCopy> forId(String id) async {
    final copies = _copies ??= parse(await rootBundle.loadString(assetPath));
    final copy = copies[id];
    if (copy == null) {
      throw FormatException('No hay contexto de entrenamiento para "$id".');
    }
    return copy;
  }

  static Map<String, TrainingContextCopy> parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('training_context.json debe ser un objeto.');
    }
    return {
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is Map)
          entry.key as String: TrainingContextCopy.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
    };
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
