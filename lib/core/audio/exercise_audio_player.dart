import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_assets.dart';

/// Snapshot of playback for a single A/B listen slot.
class ExercisePlaybackSnapshot {
  const ExercisePlaybackSnapshot({
    this.activeOption,
    this.isPlaying = false,
    this.isPaused = false,
    this.progress = 0,
    this.duration = Duration.zero,
    this.position = Duration.zero,
  });

  final String? activeOption;
  final bool isPlaying;
  final bool isPaused;
  final double progress;
  final Duration duration;
  final Duration position;

  bool isActive(String option) => activeOption == option;

  bool isPlayingOption(String option) =>
      activeOption == option && isPlaying;

  bool isPausedOption(String option) =>
      activeOption == option && isPaused;

  bool isIdleOption(String option) =>
      activeOption != option || (!isPlaying && !isPaused && progress == 0);
}

/// Lightweight asset playback for A/B listening exercises.
class ExerciseAudioPlayer {
  ExerciseAudioPlayer() {
    _player.onPlayerComplete.listen((_) {
      _position = Duration.zero;
      _playingOption = null;
      onCompleted?.call();
      onPlaybackStateChanged?.call();
    });
    _player.onPlayerStateChanged.listen((_) {
      onPlaybackStateChanged?.call();
    });
    _player.onDurationChanged.listen((duration) {
      _duration = duration;
      onPlaybackStateChanged?.call();
    });
    _player.onPositionChanged.listen((position) {
      _position = position;
      onPlaybackStateChanged?.call();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  String? _playingOption;
  String? _currentAssetPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  VoidCallback? onPlaybackStateChanged;
  VoidCallback? onCompleted;

  ExercisePlaybackSnapshot get snapshot => ExercisePlaybackSnapshot(
        activeOption: _playingOption,
        isPlaying: _player.state == PlayerState.playing,
        isPaused: _player.state == PlayerState.paused,
        progress: _progress,
        duration: _duration,
        position: _position,
      );

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> playOption(
    String option,
    String assetPath, {
    Duration Function()? resolveStart,
  }) async {
    final sameTrack = _playingOption == option && _currentAssetPath == assetPath;

    if (!sameTrack) {
      await _player.stop();
      final start = resolveStart?.call() ?? Duration.zero;
      _playingOption = option;
      _currentAssetPath = assetPath;
      _duration = Duration.zero;
      _position = start;
      await _player.play(
        AssetSource(AppAssets.audioSourcePath(assetPath)),
        position: start,
      );
      onPlaybackStateChanged?.call();
      return;
    }

    switch (_player.state) {
      case PlayerState.playing:
        await _player.pause();
      case PlayerState.paused:
        await _player.resume();
      case PlayerState.stopped:
      case PlayerState.completed:
        _position = Duration.zero;
        await _player.stop();
        await _player.play(
          AssetSource(AppAssets.audioSourcePath(assetPath)),
          position: Duration.zero,
        );
      case PlayerState.disposed:
        break;
    }
    onPlaybackStateChanged?.call();
  }

  Future<void> replayOption(String option, String assetPath) async {
    await _player.stop();
    _playingOption = option;
    _currentAssetPath = assetPath;
    _position = Duration.zero;
    await _player.play(
      AssetSource(AppAssets.audioSourcePath(assetPath)),
      position: Duration.zero,
    );
    onPlaybackStateChanged?.call();
  }

  Future<void> seekToFraction(double fraction) async {
    if (_duration.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
    );
    await seekTo(target);
  }

  Future<void> seekTo(Duration target) async {
    if (_duration.inMilliseconds <= 0) return;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    await _player.seek(clamped);
    _position = clamped;
    onPlaybackStateChanged?.call();
  }

  Future<void> stop() async {
    await _player.stop();
    _playingOption = null;
    _currentAssetPath = null;
    _duration = Duration.zero;
    _position = Duration.zero;
    onPlaybackStateChanged?.call();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
