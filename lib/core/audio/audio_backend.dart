import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../constants/app_assets.dart';

/// What actually plays the sound under [ExerciseAudioPlayer].
///
/// Native apps use audioplayers. The web uses a plain HTML audio element
/// (see web_audio_backend.dart): audioplayers routes web audio through an
/// AudioContext, which Chrome on Android can leave suspended, so Play
/// shows the time but stays silent.
abstract class AudioBackend {
  PlayerState get state;
  Stream<void> get onComplete;
  Stream<void> get onStateChanged;
  Stream<Duration> get onDuration;
  Stream<Duration> get onPosition;

  /// Starts loading [assetPath] without playing it. Never waits for the
  /// download.
  Future<void> prepare(String assetPath);

  /// Plays [assetPath] from the beginning.
  Future<void> playFromStart(String assetPath);
  Future<void> pause();
  Future<void> resume();

  /// Stops and rewinds.
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// audioplayers, for Android and iOS apps (and tests).
class NativeAudioBackend implements AudioBackend {
  NativeAudioBackend() {
    _ready = _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _ready;

  @override
  PlayerState get state => _player.state;
  @override
  Stream<void> get onComplete => _player.onPlayerComplete;
  @override
  Stream<void> get onStateChanged => _player.onPlayerStateChanged;
  @override
  Stream<Duration> get onDuration => _player.onDurationChanged;
  @override
  Stream<Duration> get onPosition => _player.onPositionChanged;

  @override
  Future<void> prepare(String assetPath) async {
    await _ready;
    await _player.setSource(AssetSource(AppAssets.audioSourcePath(assetPath)));
  }

  /// Stop, rewind and play. Do not pass `position` into [AudioPlayer.play]:
  /// `stop()` already rewinds the element with [ReleaseMode.stop].
  @override
  Future<void> playFromStart(String assetPath) async {
    await _ready;
    await _player.stop();
    await _player.play(AssetSource(AppAssets.audioSourcePath(assetPath)));
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> dispose() => _player.dispose();
}
