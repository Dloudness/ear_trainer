import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_assets.dart';

/// What a play-button tap did. Only [started] counts as a new listen.
enum ListenAction { started, paused, resumed }

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

  bool isPlayingOption(String option) => activeOption == option && isPlaying;

  bool isPausedOption(String option) => activeOption == option && isPaused;

  bool isIdleOption(String option) =>
      activeOption != option || (!isPlaying && !isPaused && progress == 0);
}

/// Lightweight asset playback for listening exercises.
///
/// Commands run one at a time so a burst of taps cannot stack sounds.
class ExerciseAudioPlayer {
  ExerciseAudioPlayer() {
    _ready = _player.setReleaseMode(ReleaseMode.stop);
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

  static const maxListens = 3;

  final AudioPlayer _player = AudioPlayer();
  String? _playingOption;
  String? _currentAssetPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Future<void> _tail = Future<void>.value();
  late final Future<void> _ready;
  var _disposed = false;

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
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  Future<T> _run<T>(Future<T> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  /// Play toggles the current clip. A stopped or finished clip always
  /// restarts from the beginning; pause and resume stay where they were.
  Future<ListenAction> playOption(String option, String assetPath) {
    return _run(() => _playOption(option, assetPath));
  }

  Future<ListenAction> _playOption(String option, String assetPath) async {
    await _ready;
    if (_disposed) return ListenAction.paused;

    final sameTrack =
        _playingOption == option && _currentAssetPath == assetPath;
    if (sameTrack && _player.state == PlayerState.playing) {
      await _player.pause();
      onPlaybackStateChanged?.call();
      return ListenAction.paused;
    }
    if (sameTrack && _player.state == PlayerState.paused) {
      await _player.resume();
      onPlaybackStateChanged?.call();
      return ListenAction.resumed;
    }

    await _startFromZero(option, assetPath);
    return ListenAction.started;
  }

  /// Starts a stopped clip without toggling one that is already playing.
  /// A scrub can fire several times before the first start finishes; those
  /// later calls must not turn into a pause.
  Future<ListenAction?> startIfIdle(String option, String assetPath) {
    return _run(() async {
      await _ready;
      if (_disposed) return null;
      final sameTrack =
          _playingOption == option && _currentAssetPath == assetPath;
      final active =
          _player.state == PlayerState.playing ||
          _player.state == PlayerState.paused;
      if (sameTrack && active) return null;
      await _startFromZero(option, assetPath);
      return ListenAction.started;
    });
  }

  /// Stop, rewind and play. Do not pass `position` into [AudioPlayer.play].
  ///
  /// On Chrome, `ReleaseMode.release` (the plugin default) destroys the
  /// HTML audio element on stop and on natural end, but keeps the URL.
  /// `play(sameAsset, position: Duration.zero)` then waits for a `seeked`
  /// event that never fires, so playback never starts. `stop()` already
  /// rewinds the element when the release mode is [ReleaseMode.stop], and
  /// `play` without a position starts that rewound element.
  Future<void> _startFromZero(String option, String assetPath) async {
    await _player.stop();
    if (_disposed) return;
    _playingOption = option;
    _currentAssetPath = assetPath;
    _position = Duration.zero;
    await _player.play(AssetSource(AppAssets.audioSourcePath(assetPath)));
    onPlaybackStateChanged?.call();
  }

  Future<void> seekToFraction(double fraction) {
    return _run(() async {
      if (_duration.inMilliseconds <= 0 || _disposed) return;
      final target = Duration(
        milliseconds: (_duration.inMilliseconds * fraction.clamp(0.0, 1.0))
            .round(),
      );
      await _seek(target);
    });
  }

  Future<void> seekTo(Duration target) {
    return _run(() async {
      if (_disposed) return;
      await _seek(target);
    });
  }

  Future<void> _seek(Duration target) async {
    if (_duration.inMilliseconds <= 0) return;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    if ((clamped - _position).inMilliseconds.abs() < 50) return;
    await _player.seek(clamped);
    _position = clamped;
    onPlaybackStateChanged?.call();
  }

  Future<void> stop() {
    return _run(() async {
      await _player.stop();
      _playingOption = null;
      _currentAssetPath = null;
      _duration = Duration.zero;
      _position = Duration.zero;
      onPlaybackStateChanged?.call();
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    await _player.dispose();
  }
}
