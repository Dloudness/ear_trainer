import 'audio_backend.dart';

/// Outside the web there is no HTML audio element: use audioplayers.
AudioBackend createAudioBackend() => NativeAudioBackend();
