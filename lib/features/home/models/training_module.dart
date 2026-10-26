import 'package:flutter/material.dart';

import 'module_icon_type.dart';

class TrainingModule {
  const TrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.iconType,
    required this.accentStart,
    required this.accentEnd,
    this.progress = 0,
    this.route,
  });

  final String id;
  final String title;
  final String description;
  final ModuleIconType iconType;
  final Color accentStart;
  final Color accentEnd;
  final double progress;
  final String? route;

  TrainingModule copyWith({double? progress}) {
    return TrainingModule(
      id: id,
      title: title,
      description: description,
      iconType: iconType,
      accentStart: accentStart,
      accentEnd: accentEnd,
      progress: progress ?? this.progress,
      route: route,
    );
  }
}
