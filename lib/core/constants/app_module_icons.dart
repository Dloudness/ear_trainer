import '../constants/app_assets.dart';
import '../../features/home/models/module_icon_type.dart';

abstract final class AppModuleIcons {
  static String forModuleId(String id) => switch (id) {
        'frecuencias' => AppAssets.demoFrequencies,
        'dinamica' => AppAssets.demoDynamics,
        'entrenamiento_musical' => AppAssets.demoMusical,
        'escucha_real' => AppAssets.demoListening,
        _ => AppAssets.demoFrequencies,
      };

  static String forIconType(ModuleIconType type) => switch (type) {
        ModuleIconType.frequency => AppAssets.demoFrequencies,
        ModuleIconType.gauge => AppAssets.demoDynamics,
        ModuleIconType.piano => AppAssets.demoMusical,
        ModuleIconType.headphones => AppAssets.demoListening,
        ModuleIconType.waveform => AppAssets.demoFrequencies,
        ModuleIconType.eqGraph => AppAssets.demoFrequencies,
        ModuleIconType.live => AppAssets.demoListening,
      };
}
