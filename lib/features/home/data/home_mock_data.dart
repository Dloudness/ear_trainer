import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../models/module_icon_type.dart';
import '../models/training_module.dart';

abstract final class HomeMockData {
  /// Home carousel — four core modules only.
  static const carouselModules = [
    TrainingModule(
      id: 'frecuencias',
      title: 'Frecuencias',
      description: 'Detecta rangos, balance y fatiga tonal.',
      iconType: ModuleIconType.frequency,
      accentStart: AppColors.cyan,
      accentEnd: AppColors.purpleLight,
      progress: 0,
      route: AppRoutes.moduleFrecuencias,
    ),
    TrainingModule(
      id: 'dinamica',
      title: 'Dinámica',
      description: 'Compresión, punch y control dinámico.',
      iconType: ModuleIconType.gauge,
      accentStart: AppColors.orange,
      accentEnd: AppColors.amber,
      progress: 0,
      route: AppRoutes.moduleDinamica,
    ),
    TrainingModule(
      id: 'escucha_real',
      title: 'Escucha Real',
      description: 'Analiza grabaciones profesionales.',
      iconType: ModuleIconType.headphones,
      accentStart: AppColors.blue,
      accentEnd: AppColors.pink,
      progress: 0,
      route: AppRoutes.moduleEscuchaReal,
    ),
    TrainingModule(
      id: 'entrenamiento_musical',
      title: 'Entrenamiento Musical',
      description: 'Intervalos, acordes y percepción armónica.',
      iconType: ModuleIconType.piano,
      accentStart: Color(0xFF818CF8),
      accentEnd: AppColors.purple,
      progress: 0,
      route: AppRoutes.moduleMusical,
    ),
  ];

  static TrainingModule? moduleById(String id) {
    for (final module in carouselModules) {
      if (module.id == id) return module;
    }
    return null;
  }

  static const dailyChallengeQuestion = '¿La voz suena muddy o harsh?';

  static const earTodayInsight = 'Tus medios se sienten más despejados que ayer.';
  static const earTodayDetail = 'Sigue entrenando la claridad vocal y el balance tonal.';

  static const recommendedListenTitle = 'Referencia vocal en contexto';
  static const recommendedListenDetail = 'Escucha una toma seca y procesada para comparar presencia.';
}
