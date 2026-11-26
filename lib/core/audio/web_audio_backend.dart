import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../constants/app_assets.dart';
import 'audio_backend.dart';

AudioBackend createAudioBackend() => WebAudioBackend();

/// A plain HTML audio element, straight to the speakers.
///
/// No AudioContext in between: on Chrome for Android a context can stay
/// suspended (screen off, another app took the sound, first visit), and
/// then every Play shows the time but is silent. `play()` is called right
/// away inside the tap, without waiting for the file to load.
class WebAudioBackend implements AudioBackend {
  WebAudioBackend() {
    final el = _el;
    el.preload = 'auto';
    _subs.addAll([
      web.EventStreamProviders.playingEvent.forElement(el).listen((_) {
        _setState(PlayerState.playing);
        _startTicker();
      }),
      web.EventStreamProviders.pauseEvent.forElement(el).listen((_) {
        if (_state == PlayerState.playing) _setState(PlayerState.paused);
        _stopTicker();
      }),
      web.EventStreamProviders.endedEvent.forElement(el).listen((_) {
        _stopTicker();
        el.currentTime = 0;
        _setState(PlayerState.completed);
        _complete.add(null);
      }),
      web.EventStreamProviders.durationChangeEvent.forElement(el).listen((_) {
        _emitDuration();
      }),
      web.EventStreamProviders.loadedMetadataEvent.forElement(el).listen((_) {
        _emitDuration();
      }),
      web.EventStreamProviders.errorEvent.forElement(el).listen((_) {
        debugPrint('Audio web: no se pudo cargar ${el.src}');
        _stopTicker();
        _setState(PlayerState.stopped);
      }),
    ]);
  }

  final web.HTMLAudioElement _el = web.HTMLAudioElement();
  final _subs = <StreamSubscription<web.Event>>[];
  final _complete = StreamController<void>.broadcast();
  final _stateChanged = StreamController<void>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  PlayerState _state = PlayerState.stopped;
  String? _url;
  Timer? _ticker;

  @override
  PlayerState get state => _state;
  @override
  Stream<void> get onComplete => _complete.stream;
  @override
  Stream<void> get onStateChanged => _stateChanged.stream;
  @override
  Stream<Duration> get onDuration => _duration.stream;
  @override
  Stream<Duration> get onPosition => _position.stream;

  void _setState(PlayerState state) {
    if (_state == state) return;
    _state = state;
    _stateChanged.add(null);
  }

  void _emitDuration() {
    final seconds = _el.duration;
    if (seconds.isFinite && seconds > 0) {
      _duration.add(_toDuration(seconds));
    }
  }

  static Duration _toDuration(num seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  /// Smooth progress while playing (timeupdate fires only ~4 times a second).
  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      _position.add(_toDuration(_el.currentTime));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _position.add(_toDuration(_el.currentTime));
  }

  String _urlFor(String assetPath) =>
      ui_web.assetManager.getAssetUrl(AppAssets.bundle(assetPath));

  void _load(String assetPath) {
    final url = _urlFor(assetPath);
    if (_url == url) return;
    _url = url;
    _el.src = url;
    _el.load();
  }

  @override
  Future<void> prepare(String assetPath) async => _load(assetPath);

  @override
  Future<void> playFromStart(String assetPath) async {
    _load(assetPath);
    _el.pause();
    _el.currentTime = 0;
    await _play();
  }

  Future<void> _play() async {
    // Mark it playing at once so the button answers the tap; the
    // "playing" event confirms it when the sound actually starts.
    _setState(PlayerState.playing);
    try {
      await _el.play().toDart;
    } catch (error) {
      _setState(PlayerState.stopped);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    _el.pause();
    _setState(PlayerState.paused);
  }

  @override
  Future<void> resume() => _play();

  @override
  Future<void> stop() async {
    _el.pause();
    if (_el.readyState > 0) _el.currentTime = 0;
    _stopTicker();
    _setState(PlayerState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    _el.currentTime = position.inMilliseconds / 1000;
    _position.add(position);
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _el.pause();
    _el.removeAttribute('src');
    _el.load();
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _complete.close();
    await _stateChanged.close();
    await _duration.close();
    await _position.close();
  }
}
