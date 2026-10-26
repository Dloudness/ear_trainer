import 'package:flutter/material.dart';

class PlaceholderExerciseArgs {
  const PlaceholderExerciseArgs({
    required this.title,
    required this.comingSoon,
    required this.accent,
    this.moduleTitle,
  });

  final String title;
  final String comingSoon;
  final Color accent;
  final String? moduleTitle;
}
