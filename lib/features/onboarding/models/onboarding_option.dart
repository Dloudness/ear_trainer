import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/models/module_icon_type.dart';

enum OnboardingOption {
  ecualizacionFrecuencias(
    'Ecualización y frecuencias',
    'Detecta rangos, balance y excesos tonales.',
    ModuleIconType.frequency,
    AppColors.cyan,
  ),
  dinamicaCompresion(
    'Dinámica y compresión',
    'Entrena punch, control dinámico y compresión.',
    ModuleIconType.gauge,
    AppColors.orange,
  ),
  entrenamientoMusical(
    'Entrenamiento musical',
    'Intervalos, acordes y percepción armónica.',
    ModuleIconType.piano,
    AppColors.purpleLight,
  ),
  escuchaReal(
    'Escucha real',
    'Analiza voces, mezclas y referencias profesionales.',
    ModuleIconType.live,
    AppColors.blue,
  );

  const OnboardingOption(
    this.title,
    this.description,
    this.iconType,
    this.accent,
  );

  final String title;
  final String description;
  final ModuleIconType iconType;
  final Color accent;
}
