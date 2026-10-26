abstract final class AppAssets {
  static const homeBackground = 'assets/mockup/home_reference.png';

  static const logo = 'assets/icons/logo_main.png';
  static const demoFrequencies = 'assets/icons/demo_frequencies.png';
  static const demoDynamics = 'assets/icons/demo_dynamics.png';
  static const demoMusical = 'assets/icons/demo_musical.png';
  static const demoListening = 'assets/icons/demo_listening.png';

  static const guitarAcoustic01 = 'assets/source/guitar_acoustic_01.wav';
  static const voiceNarration01 = 'assets/source/voice_narration_01.wav';
  static const musicInstrumental01 = 'assets/source/music_instrumental_01.wav';

  static const guitarAcoustic01BoomyDark =
      'assets/eq/guitar_acoustic_01_boomy_dark.wav';
  static const guitarAcoustic01Thin = 'assets/eq/guitar_acoustic_01_thin.wav';
  static const voiceNarration01Muddy = 'assets/eq/voice_narration_01_muddy.wav';
  static const voiceNarration01Scooped =
      'assets/eq/voice_narration_01_scooped.wav';
  static const musicInstrumental01Harsh =
      'assets/eq/music_instrumental_01_harsh.wav';

  static const musicEpicStrings01 = 'assets/music/music_epic_strings_01.wav';
  static const musicTensionStrings01 =
      'assets/music/music_tension_strings_01.wav';

  static const ambientFieldBirds01 =
      'assets/ambient/ambient_field_birds_01.wav';
  static const ambientFieldColdRain01 =
      'assets/ambient/ambient_field_cold_rain_01.wav';

  static const sceneGymDark = 'assets/video/source/scene_gym_dark.mp4';
  static const sceneGirlField01 = 'assets/video/source/scene_girl_field_01.mp4';

  /// Asset path for [AssetSource], relative to the assets folder.
  static String audioSourcePath(String path) {
    final bundled = bundle(path);
    return bundled.startsWith('assets/') ? bundled.substring('assets/'.length) : bundled;
  }

  /// Returns the Flutter asset key with exactly one `assets/` prefix.
  static String bundle(String path) {
    var normalized = path.replaceAll('\\', '/');

    while (normalized.startsWith('assets/assets/')) {
      normalized = normalized.substring('assets/'.length);
    }

    if (normalized.startsWith('assets/')) {
      return normalized;
    }

    return 'assets/$normalized';
  }
}
