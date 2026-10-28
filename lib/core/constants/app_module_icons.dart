import 'package:flutter/material.dart';

import '../../features/home/models/module_icon_type.dart';

abstract final class AppModuleIcons {
  static IconData forModuleId(String id) => switch (id) {
        'frecuencias' => Icons.equalizer,
        'dinamica' => Icons.graphic_eq,
        'entrenamiento_musical' => Icons.piano,
        'escucha_real' => Icons.headphones,
        _ => Icons.equalizer,
      };

  static IconData forIconType(ModuleIconType type) => switch (type) {
        ModuleIconType.frequency || ModuleIconType.eqGraph => Icons.equalizer,
        ModuleIconType.gauge || ModuleIconType.waveform => Icons.graphic_eq,
        ModuleIconType.piano => Icons.piano,
        ModuleIconType.headphones || ModuleIconType.live => Icons.headphones,
      };
}
