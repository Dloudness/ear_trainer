import 'dart:async';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/foundation.dart';

import 'audio_backend.dart';
import 'web_audio_backend_stub.dart'
    if (dart.library.js_interop) 'web_audio_backend.dart';

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
/// Commands run one at a time so a burst of taps cannot stack sounds. None
/// can block the ones after it: a command that does not answer in a few
/// seconds is dropped, so the next Play always works.
class ExerciseAudioPlayer {
  ExerciseAudioPlayer() {
    _backend.onComplete.listen((_) {
      _position = Duration.zero;
      _playingOption = null;
      onCompleted?.call();
      onPlaybackStateChanged?.call();
    });
    _backend.onStateChanged.listen((_) {
      onPlaybackStateChanged?.call();
    });
    _backend.onDuration.listen((duration) {
      _duration = duration;
      onPlaybackStateChanged?.call();
    });
    _backend.onPosition.listen((position) {
      _position = position;
      onPlaybackStateChanged?.call();
    });
  }

  static const maxListens = 3;

  /// Longest a command may take before the queue moves on.
  static const _commandTimeout = Duration(seconds: 6);

  final AudioBackend _backend = createAudioBackend();
  String? _playingOption;
  String? _currentAssetPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Future<void> _tail = Future<void>.value();
  var _disposed = false;

  VoidCallback? onPlaybackStateChanged;
  VoidCallback? onCompleted;

  ExercisePlaybackSnapshot get snapshot => ExercisePlaybackSnapshot(
    activeOption: _playingOption,
    isPlaying: _backend.state == PlayerState.playing,
    isPaused: _backend.state == PlayerState.paused,
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

  Future<T> _run<T>(
    Future<T> Function() action, {
    Duration timeout = _commandTimeout,
  }) {
    final run = _tail.then((_) => _limited(action(), timeout));
    _tail = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  final _timers = <Timer>{};

  /// [future], or a [TimeoutException] after [timeout]. The timer is
  /// cancelled on [dispose], so a closed screen leaves nothing pending.
  Future<T> _limited<T>(Future<T> future, Duration timeout) {
    final completer = Completer<T>();
    late final Timer timer;
    timer = Timer(timeout, () {
      _timers.remove(timer);
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('audio', timeout));
      }
    });
    _timers.add(timer);
    future.then(
      (value) {
        timer.cancel();
        _timers.remove(timer);
        if (!completer.isCompleted) completer.complete(value);
      },
      onError: (Object error, StackTrace stack) {
        timer.cancel();
        _timers.remove(timer);
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    return completer.future;
  }

  /// Play toggles the current clip. A stopped or finished clip always
  /// restarts from the beginning; pause and resume stay where they were.
  Future<ListenAction> playOption(String option, String assetPath) {
    return _run(() => _playOption(option, assetPath));
  }

  Future<ListenAction> _playOption(String option, String assetPath) async {
    if (_disposed) return ListenAction.paused;

    final sameTrack =
        _playingOption == option && _currentAssetPath == assetPath;
    if (sameTrack && _backend.state == PlayerState.playing) {
      await _backend.pause();
      onPlaybackStateChanged?.call();
      return ListenAction.paused;
    }
    if (sameTrack && _backend.state == PlayerState.paused) {
      await _backend.resume();
      onPlaybackStateChanged?.call();
      return ListenAction.resumed;
    }

    await _startFromZero(option, assetPath);
    return ListenAction.started;
  }

  /// Loads a clip without playing it, so the first Play sounds at once.
  /// Does nothing while another clip is playing or paused, and never makes
  /// a Play wait for long.
  Future<void> preload(String assetPath) {
    return _run(() async {
      if (_disposed) return;
      final active =
          _backend.state == PlayerState.playing ||
          _backend.state == PlayerState.paused;
      if (active || _currentAssetPath == assetPath) return;
      try {
        await _backend.prepare(assetPath);
        _currentAssetPath = assetPath;
      } catch (_) {
        // Preloading is only a speed-up; Play loads the clip anyway.
      }
    }, timeout: const Duration(seconds: 2)).catchError((Object _) {});
  }

  /// Starts a stopped clip without toggling one that is already playing.
  /// A scrub can fire several times before the first start finishes; those
  /// later calls must not turn into a pause.
  Future<ListenAction?> startIfIdle(String option, String assetPath) {
    return _run(() async {
      if (_disposed) return null;
      final sameTrack =
          _playingOption == option && _currentAssetPath == assetPath;
      final active =
          _backend.state == PlayerState.playing ||
          _backend.state == PlayerState.paused;
      if (sameTrack && active) return null;
      await _startFromZero(option, assetPath);
      return ListenAction.started;
    });
  }

  Future<void> _startFromZero(String option, String assetPath) async {
    if (_disposed) return;
    _playingOption = option;
    _currentAssetPath = assetPath;
    _position = Duration.zero;
    await _backend.playFromStart(assetPath);
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
    await _backend.seek(clamped);
    _position = clamped;
    onPlaybackStateChanged?.call();
  }

  Future<void> stop() {
    return _run(() async {
      await _backend.stop();
      _playingOption = null;
      _currentAssetPath = null;
      _duration = Duration.zero;
      _position = Duration.zero;
      onPlaybackStateChanged?.call();
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    await _backend.dispose();
  }
}
