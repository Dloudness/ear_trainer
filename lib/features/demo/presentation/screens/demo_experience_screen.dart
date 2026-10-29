import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/audio/exercise_audio_player.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/option_choice_palette.dart';
import '../../../../core/widgets/exercise_listen_card.dart';
import '../../../../core/widgets/exercise_typography.dart';
import '../../../../core/widgets/option_choice_card.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../home/presentation/widgets/module_neon_icon.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../exercises/data/exercise_repository.dart';
import '../../../exercises/models/exercise.dart';
import '../../../onboarding/models/onboarding_option.dart';
import '../../models/category_demo_content.dart';
import '../../models/escucha_real_exercises.dart';
import '../../models/exercise_demo_mapper.dart';

enum _DemoPhase { intro, video, listen, feedback, reveal }

class DemoExperienceScreen extends StatefulWidget {
  const DemoExperienceScreen({
    super.key,
    this.category,
    this.exerciseIndex = 0,
  });

  final OnboardingOption? category;
  final int exerciseIndex;

  @override
  State<DemoExperienceScreen> createState() => _DemoExperienceScreenState();
}

class _DemoExperienceScreenState extends State<DemoExperienceScreen>
    with TickerProviderStateMixin {
  _DemoPhase _phase = _DemoPhase.intro;
  String? _selectedOption;

  late final OnboardingOption _category;
  late CategoryDemoContent _content;
  late final ExerciseAudioPlayer _audioPlayer;
  late final Random _random;
  late int _exerciseIndex;
  VideoPlayerController? _videoController;
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<double> _pulse;

  Timer? _mockPlaybackTimer;
  Timer? _resyncTimer;
  String? _mockPlayingOption;
  bool _mockPaused = false;
  int _mockPositionMs = 0;
  static const _mockDurationMs = 2200;
  static const _syncDrift = Duration(milliseconds: 150);
  bool _finishingPair = false;
  bool _sharedEndArmed = false;
  bool _holdingSync = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category ?? OnboardingOption.escuchaReal;
    _exerciseIndex = widget.exerciseIndex;
    _random = Random();
    _content = _buildContentForCurrentExercise();
    _audioPlayer = ExerciseAudioPlayer()
      ..onPlaybackStateChanged = () {
        if (!mounted) return;
        _maybeFinishTogether();
        setState(() {});
      }
      ..onCompleted = () {
        if (!mounted || !_hasVideo) return;
        unawaited(_finishTogether());
      };
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _mockPlaybackTimer?.cancel();
    _resyncTimer?.cancel();
    _disposeVideo();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _hasVideo => _content.videoAsset != null;

  Future<void> _initVideo() async {
    final asset = _content.videoAsset;
    if (asset == null) return;

    await _disposeVideo();
    final controller = VideoPlayerController.asset(AppAssets.bundle(asset));
    controller.addListener(_onVideoControllerTick);
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      await _disposeVideo();
    }

    if (mounted) setState(() {});
  }

  Future<void> _pauseVideo() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.pause();
  }

  Future<void> _disposeVideo() async {
    _resyncTimer?.cancel();
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      controller.removeListener(_onVideoControllerTick);
      await controller.pause();
      await controller.dispose();
    }
  }

  bool get _canSyncVideo {
    final video = _videoController;
    return _hasVideo && video != null && video.value.isInitialized;
  }

  VideoPlayerController? get _syncedVideo =>
      _canSyncVideo ? _videoController : null;

  void _onVideoControllerTick() {
    final video = _videoController;
    if (video != null && video.value.isInitialized && video.value.volume > 0.01) {
      unawaited(video.setVolume(0));
    }
    _maybeFinishTogether();
  }

  Duration? _sharedEnd() {
    final video = _syncedVideo;
    if (video == null) return null;
    final audioDuration = _audioPlayer.snapshot.duration;
    final videoDuration = video.value.duration;
    if (audioDuration <= Duration.zero || videoDuration <= Duration.zero) {
      return null;
    }
    return audioDuration < videoDuration ? audioDuration : videoDuration;
  }

  void _maybeFinishTogether() {
    if (_holdingSync ||
        _finishingPair ||
        !_sharedEndArmed ||
        _phase != _DemoPhase.listen) {
      return;
    }
    final video = _syncedVideo;
    final snap = _audioPlayer.snapshot;
    if (video == null) return;
    if (!snap.isPlaying && !video.value.isPlaying) return;
    final end = _sharedEnd();
    if (end == null || end.inMilliseconds <= 0) return;

    final limit = end - const Duration(milliseconds: 60);
    if (limit <= Duration.zero) return;
    final audioNearEnd =
        snap.position >= limit - const Duration(milliseconds: 200);
    if (!audioNearEnd) return;

    final audioHit = snap.isPlaying && snap.position >= limit;
    final videoHit = video.value.isPlaying &&
        (video.value.isCompleted || video.value.position >= limit);
    if (!audioHit && !videoHit) return;
    unawaited(_finishTogether());
  }

  Future<void> _finishTogether() async {
    if (_finishingPair || _phase != _DemoPhase.listen) return;
    _finishingPair = true;
    _sharedEndArmed = false;
    _resyncTimer?.cancel();
    final video = _videoController;
    if (video != null && video.value.isInitialized) {
      await video.pause();
      await video.seekTo(Duration.zero);
      await video.setVolume(0);
    }
    final snap = _audioPlayer.snapshot;
    if (snap.isPlaying || snap.isPaused) {
      await _audioPlayer.stop();
    }
    _finishingPair = false;
    if (mounted) setState(() {});
  }

  void _scheduleVideoResync() {
    _resyncTimer?.cancel();
    var checks = 0;
    _resyncTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      checks += 1;
      unawaited(_resyncVideoToAudio());
      if (checks >= 2) timer.cancel();
    });
  }

  Future<void> _resyncVideoToAudio() async {
    if (_holdingSync ||
        _finishingPair ||
        !_sharedEndArmed ||
        _phase != _DemoPhase.listen) {
      return;
    }
    final video = _syncedVideo;
    final snap = _audioPlayer.snapshot;
    if (video == null || (!snap.isPlaying && !snap.isPaused)) return;
    final delta = (video.value.position - snap.position).inMilliseconds.abs();
    if (delta > _syncDrift.inMilliseconds) {
      await video.seekTo(snap.position);
    }
  }

  void _prepareSyncedVideo(
    VideoPlayerController video, {
    bool seekToStart = false,
    bool play = true,
  }) {
    unawaited(video.setVolume(0));
    unawaited(video.setLooping(false));
    if (seekToStart && video.value.position > _syncDrift) {
      unawaited(video.seekTo(Duration.zero));
    }
    if (play) unawaited(video.play());
  }

  String? _assetFor(String option) =>
      option == 'A' ? _content.audioAssetA : _content.audioAssetB;

  bool _isPlaying(String option) {
    final asset = _assetFor(option);
    if (asset != null) return _audioPlayer.snapshot.isPlayingOption(option);
    return _mockPlayingOption == option && !_mockPaused;
  }

  bool _isPaused(String option) {
    final asset = _assetFor(option);
    if (asset != null) return _audioPlayer.snapshot.isPausedOption(option);
    return _mockPlayingOption == option && _mockPaused;
  }

  double _progressFor(String option) {
    final asset = _assetFor(option);
    if (asset != null) {
      final snap = _audioPlayer.snapshot;
      if (snap.isActive(option)) return snap.progress;
      return 0;
    }
    if (_mockPlayingOption == option) {
      return (_mockPositionMs / _mockDurationMs).clamp(0.0, 1.0);
    }
    return 0;
  }

  Future<void> _goToPhase(_DemoPhase phase) async {
    if (_phase == _DemoPhase.listen) {
      await _stopAllPlayback();
    }
    if (_phase == _DemoPhase.video) {
      await _pauseVideo();
    }
    await _fadeController.reverse();
    if (!mounted) return;
    setState(() {
      _phase = phase;
      if (phase == _DemoPhase.listen) {
        _selectedOption = null;
      }
    });
    if (phase == _DemoPhase.video) {
      await _initVideo();
    }
    if (phase == _DemoPhase.listen) {
      final video = _syncedVideo;
      if (video != null) await video.setVolume(0);
    }
    await _fadeController.forward();
  }

  Future<void> _stopAllPlayback() async {
    _mockPlaybackTimer?.cancel();
    _resyncTimer?.cancel();
    _sharedEndArmed = false;
    _holdingSync = false;
    _mockPlayingOption = null;
    _mockPaused = false;
    _mockPositionMs = 0;
    final video = _videoController;
    if (video != null && video.value.isInitialized && video.value.isPlaying) {
      await video.pause();
    }
    await _audioPlayer.stop();
  }

  Future<void> _playPauseOption(String option) async {
    final asset = _assetFor(option);
    if (asset != null) {
      if (_canSyncVideo) {
        await _playPauseSynced(option, asset);
      } else {
        await _audioPlayer.playOption(option, asset);
      }
      if (mounted) setState(() {});
      return;
    }

    if (_mockPlayingOption == option && !_mockPaused) {
      _mockPlaybackTimer?.cancel();
      setState(() => _mockPaused = true);
      return;
    }

    if (_mockPlayingOption == option && _mockPaused) {
      setState(() => _mockPaused = false);
      _startMockPlayback(option);
      return;
    }

    _mockPlaybackTimer?.cancel();
    setState(() {
      _mockPlayingOption = option;
      _mockPaused = false;
      _mockPositionMs = 0;
    });
    _startMockPlayback(option);
  }

  Future<void> _replayOption(String option) async {
    final asset = _assetFor(option);
    if (asset != null) {
      final video = _syncedVideo;
      if (video != null) {
        _holdingSync = true;
        _sharedEndArmed = true;
        _prepareSyncedVideo(video, seekToStart: true);
      }
      try {
        await _audioPlayer.replayOption(option, asset);
      } finally {
        _holdingSync = false;
      }
      if (video != null) _scheduleVideoResync();
      if (mounted) setState(() {});
      return;
    }

    _mockPlaybackTimer?.cancel();
    setState(() {
      _mockPlayingOption = option;
      _mockPaused = false;
      _mockPositionMs = 0;
    });
    _startMockPlayback(option);
  }

  Future<void> _seekOption(String option, double fraction) async {
    final asset = _assetFor(option);
    if (asset != null) {
      if (_canSyncVideo) {
        await _seekSynced(option, asset, fraction);
      } else {
        if (!_audioPlayer.snapshot.isActive(option)) {
          await _audioPlayer.playOption(option, asset);
        }
        await _audioPlayer.seekToFraction(fraction);
      }
      if (mounted) setState(() {});
      return;
    }

    _mockPlaybackTimer?.cancel();
    setState(() {
      _mockPlayingOption = option;
      _mockPaused = false;
      _mockPositionMs = (_mockDurationMs * fraction).round();
    });
    _startMockPlayback(option);
  }

  Future<void> _playPauseSynced(String option, String asset) async {
    final video = _syncedVideo;
    if (video == null) {
      await _audioPlayer.playOption(option, asset);
      return;
    }

    final snap = _audioPlayer.snapshot;
    final switching = snap.activeOption != null &&
        snap.activeOption != option &&
        (snap.isPlaying || snap.isPaused);

    if (switching) {
      final resumed = !video.value.isPlaying;
      _holdingSync = true;
      _sharedEndArmed = true;
      _prepareSyncedVideo(video, play: resumed);
      try {
        await _audioPlayer.playOption(
          option,
          asset,
          resolveStart: () => video.value.position,
        );
      } finally {
        _holdingSync = false;
      }
      _scheduleAudioCatchUp(video);
      return;
    }

    if (snap.isPlayingOption(option)) {
      final pausing = video.pause();
      await _audioPlayer.playOption(option, asset);
      await pausing;
      return;
    }

    _holdingSync = true;
    _sharedEndArmed = true;
    _prepareSyncedVideo(
      video,
      seekToStart: !snap.isPausedOption(option) && video.value.position > _syncDrift,
    );
    try {
      await _audioPlayer.playOption(option, asset);
    } finally {
      _holdingSync = false;
    }
    _scheduleVideoResync();
  }

  void _scheduleAudioCatchUp(VideoPlayerController video) {
    _resyncTimer?.cancel();
    var checks = 0;
    _resyncTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      checks += 1;
      unawaited(_catchAudioUpToVideo(video));
      if (checks >= 2) timer.cancel();
    });
  }

  Future<void> _catchAudioUpToVideo(VideoPlayerController video) async {
    if (!mounted || _finishingPair || _phase != _DemoPhase.listen) return;
    if (!video.value.isInitialized) return;
    final snap = _audioPlayer.snapshot;
    if ((!snap.isPlaying && !snap.isPaused) || snap.duration <= Duration.zero) {
      return;
    }
    final delta = (video.value.position - snap.position).inMilliseconds.abs();
    if (delta <= _syncDrift.inMilliseconds) return;
    final end = _sharedEnd();
    if (end != null && video.value.position >= end - const Duration(milliseconds: 60)) {
      await _finishTogether();
      return;
    }
    final target = video.value.position > snap.duration
        ? snap.duration
        : video.value.position;
    await _audioPlayer.seekTo(target);
  }

  Future<void> _seekSynced(String option, String asset, double fraction) async {
    final video = _syncedVideo;
    if (video == null) return;

    _holdingSync = true;
    _sharedEndArmed = true;
    _prepareSyncedVideo(video, play: false);
    var reachedEnd = false;
    try {
      if (!_audioPlayer.snapshot.isActive(option)) {
        unawaited(video.play());
        await _audioPlayer.playOption(option, asset);
      }
      await _audioPlayer.seekToFraction(fraction);
      final target = _audioPlayer.snapshot.position;
      final end = _sharedEnd();
      if (end != null && target >= end - const Duration(milliseconds: 60)) {
        reachedEnd = true;
      } else {
        final seeking = video.seekTo(target);
        if (_audioPlayer.snapshot.isPlaying && !video.value.isPlaying) {
          unawaited(video.play());
        }
        await seeking;
      }
    } finally {
      _holdingSync = false;
    }
    if (reachedEnd) {
      await _finishTogether();
      return;
    }
    _scheduleVideoResync();
  }

  void _startMockPlayback(String option) {
    _mockPlaybackTimer?.cancel();
    _mockPlaybackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _mockPlayingOption != option || _mockPaused) return;
      _mockPositionMs += 50;
      if (_mockPositionMs >= _mockDurationMs) {
        timer.cancel();
        setState(() {
          _mockPlayingOption = null;
          _mockPaused = false;
          _mockPositionMs = 0;
        });
        return;
      }
      setState(() {});
    });
  }

  Future<void> _selectOption(String option) async {
    await _stopAllPlayback();
    if (!mounted) return;
    setState(() => _selectedOption = option);
    await MockSession.recordExerciseResult(
      exerciseId: _currentExerciseId,
      correct: option == _content.correctOption,
    );
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _goToPhase(_DemoPhase.feedback);
    });
  }

  String get _currentExerciseId {
    if (_isEqCategory) return _currentEqExercise().id;
    if (_isEscuchaRealCategory) {
      final index = _exerciseIndex.clamp(
        0,
        EscuchaRealExercises.exercises.length - 1,
      );
      return EscuchaRealExercises.exercises[index].id;
    }
    return switch (_category) {
      OnboardingOption.dinamicaCompresion => 'DYN_01',
      _ => '${_category.name}_$_exerciseIndex',
    };
  }

  bool get _isEqCategory =>
      _category == OnboardingOption.ecualizacionFrecuencias;

  bool get _isEscuchaRealCategory =>
      _category == OnboardingOption.escuchaReal;

  bool get _isCorrectAnswer => _selectedOption == _content.correctOption;

  Exercise _currentEqExercise() {
    final exercises = ExerciseRepository.instance.byModule(
      OnboardingOption.ecualizacionFrecuencias.name,
    );
    if (exercises.isEmpty) {
      throw StateError('No hay ejercicios de ecualización cargados.');
    }
    final index = _exerciseIndex.clamp(0, exercises.length - 1);
    return exercises[index];
  }

  CategoryDemoContent _buildContentForCurrentExercise() {
    if (_isEqCategory) {
      return ExerciseDemoMapper.toContent(
        _currentEqExercise(),
        random: _random,
      );
    }
    if (_isEscuchaRealCategory) {
      final index = _exerciseIndex.clamp(
        0,
        EscuchaRealExercises.exercises.length - 1,
      );
      return EscuchaRealExercises.toDemoContent(
        EscuchaRealExercises.exercises[index],
        random: _random,
      );
    }
    return CategoryDemoContent.forCategory(_category);
  }

  Future<void> _retryExercise() async {
    await _stopAllPlayback();
    if (!mounted) return;
    setState(() => _selectedOption = null);
    await _goToPhase(_DemoPhase.listen);
  }

  Future<void> _showAnswerReveal() async {
    await _goToPhase(_DemoPhase.reveal);
  }

  Future<void> _enterLightHome() async {
    await MockSession.completeDemo();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              CinematicNavBar(
                backLabel: 'Back',
                onBack: _phase == _DemoPhase.intro ? null : () {
                  switch (_phase) {
                    case _DemoPhase.video:
                      _goToPhase(_DemoPhase.intro);
                    case _DemoPhase.listen:
                      _goToPhase(_hasVideo ? _DemoPhase.video : _DemoPhase.intro);
                    case _DemoPhase.feedback:
                      _goToPhase(_DemoPhase.listen);
                    case _DemoPhase.reveal:
                      _goToPhase(_DemoPhase.feedback);
                    case _DemoPhase.intro:
                      Navigator.maybePop(context);
                  }
                },
              ),
              Expanded(child: _buildPhaseContent()),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    return switch (_phase) {
      _DemoPhase.intro => _IntroPhase(
          pulse: _pulse,
          category: _category,
          content: _content,
        ),
      _DemoPhase.video => _VideoPhase(
          content: _content,
          accent: _category.accent,
          controller: _videoController,
        ),
      _DemoPhase.listen => _ListenPhase(
          pulse: _pulse,
          content: _content,
          accent: _category.accent,
          videoController: _hasVideo ? _videoController : null,
          isPlaying: _isPlaying,
          isPaused: _isPaused,
          progressFor: _progressFor,
          onPlayPause: _playPauseOption,
          onReplay: _replayOption,
          onSeek: _seekOption,
          onSelect: _selectOption,
        ),
      _DemoPhase.feedback => _FeedbackPhase(
          pulse: _pulse,
          content: _content,
          accent: _category.accent,
          isCorrect: _isCorrectAnswer,
        ),
      _DemoPhase.reveal => _AnswerRevealPhase(
          pulse: _pulse,
          content: _content,
          accent: _category.accent,
        ),
    };
  }

  Widget _buildBottomAction() {
    return switch (_phase) {
      _DemoPhase.intro => SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: _hasVideo ? 'VER ESCENA' : 'ESCUCHAR',
            icon: Icons.play_arrow_rounded,
            emphasized: true,
            onPressed: () => _goToPhase(
              _hasVideo ? _DemoPhase.video : _DemoPhase.listen,
            ),
          ),
        ),
      _DemoPhase.video => SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'ESCUCHAR',
            icon: Icons.play_arrow_rounded,
            emphasized: true,
            onPressed: () => _goToPhase(_DemoPhase.listen),
          ),
        ),
      _DemoPhase.listen => const SizedBox(height: 50),
      _DemoPhase.feedback => _buildFeedbackActions(),
      _DemoPhase.reveal => _buildRevealActions(),
    };
  }

  Widget _buildFeedbackActions() {
    if (_isCorrectAnswer) {
      return SizedBox(
        width: double.infinity,
        child: GradientButton(
          label: 'EXPLORAR APP',
          onPressed: _enterLightHome,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'VOLVER A INTENTAR',
            onPressed: _retryExercise,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'VER RESPUESTA',
            compact: true,
            onPressed: _showAnswerReveal,
          ),
        ),
      ],
    );
  }

  Widget _buildRevealActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'REINTENTAR EJERCICIO',
            onPressed: _retryExercise,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'EXPLORAR APP',
            compact: true,
            onPressed: _enterLightHome,
          ),
        ),
      ],
    );
  }
}

class _VideoPhase extends StatelessWidget {
  const _VideoPhase({
    required this.content,
    required this.accent,
    required this.controller,
  });

  final CategoryDemoContent content;
  final Color accent;
  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final isReady =
        controller != null && controller!.value.isInitialized;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExerciseFocusHeader(
          instruction: content.introTitle,
          question: content.question,
          hint: 'Observa la escena antes de escuchar las opciones.',
          questionSize: 24,
        ),
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: isReady ? controller!.value.aspectRatio : 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: isReady
                  ? VideoPlayer(controller!)
                  : Center(
                      child: CircularProgressIndicator(
                        color: accent.withValues(alpha: 0.8),
                        strokeWidth: 2,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroPhase extends StatelessWidget {
  const _IntroPhase({
    required this.pulse,
    required this.category,
    required this.content,
  });

  final Animation<double> pulse;
  final OnboardingOption category;
  final CategoryDemoContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: pulse,
          child: ModuleNeonIcon(
            type: category.iconType,
            accentStart: category.accent,
            accentEnd: category.accent,
            isActive: true,
            size: 88,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          category.title,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: category.accent),
        ),
        const SizedBox(height: 20),
        ExerciseFocusHeader(
          instruction: content.introTitle,
          question: content.question,
          hint: content.introSubtitle,
          questionSize: 26,
        ),
      ],
    );
  }
}

class _ListenPhase extends StatelessWidget {
  const _ListenPhase({
    required this.pulse,
    required this.content,
    required this.accent,
    required this.videoController,
    required this.isPlaying,
    required this.isPaused,
    required this.progressFor,
    required this.onPlayPause,
    required this.onReplay,
    required this.onSeek,
    required this.onSelect,
  });

  final Animation<double> pulse;
  final CategoryDemoContent content;
  final Color accent;
  final VideoPlayerController? videoController;
  final bool Function(String option) isPlaying;
  final bool Function(String option) isPaused;
  final double Function(String option) progressFor;
  final ValueChanged<String> onPlayPause;
  final ValueChanged<String> onReplay;
  final void Function(String option, double fraction) onSeek;
  final ValueChanged<String> onSelect;

  Widget _buildListenCard(String option, OptionSlot slot, String label) {
    return ExerciseListenCard(
      slot: slot,
      label: label,
      isPlaying: isPlaying(option),
      isPaused: isPaused(option),
      progress: progressFor(option),
      pulse: pulse,
      onPlayPause: () => onPlayPause(option),
      onReplay: () => onReplay(option),
      onSeek: (fraction) => onSeek(option, fraction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = videoController;
    final children = <Widget>[
      ExerciseFocusHeader(
        instruction: content.introTitle,
        question: content.question,
        hint: content.listenHint,
        questionSize: 24,
      ),
      const SizedBox(height: 28),
      if (scene != null) ...[
        _SceneVideoFrame(controller: scene, accent: accent),
        const SizedBox(height: 20),
      ],
      if (content.singleListen)
        _buildListenCard('A', OptionSlot.a, content.optionALabel)
      else ...[
        _buildListenCard('A', OptionSlot.a, content.optionALabel),
        const SizedBox(height: 14),
        _buildListenCard('B', OptionSlot.b, content.optionBLabel),
      ],
      const SizedBox(height: 28),
      Text(
        'Tu respuesta',
        style: AppTypography.exerciseInstruction,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OptionChoiceCard(
              slot: OptionSlot.a,
              label: content.choiceA,
              selected: false,
              pulse: pulse,
              showWaveform: true,
              onTap: () => onSelect('A'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OptionChoiceCard(
              slot: OptionSlot.b,
              label: content.choiceB,
              selected: false,
              pulse: pulse,
              showWaveform: true,
              onTap: () => onSelect('B'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'Tómate tu tiempo antes de responder.',
        textAlign: TextAlign.center,
        style: AppTypography.exerciseHint,
      ),
    ];

    if (scene == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _SceneVideoFrame extends StatelessWidget {
  const _SceneVideoFrame({
    required this.controller,
    required this.accent,
  });

  final VideoPlayerController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ready = controller.value.isInitialized;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AspectRatio(
          aspectRatio: ready && controller.value.aspectRatio > 0
              ? controller.value.aspectRatio
              : 16 / 9,
          child: ready
              ? VideoPlayer(controller)
              : Center(
                  child: CircularProgressIndicator(
                    color: accent.withValues(alpha: 0.8),
                    strokeWidth: 2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FeedbackPhase extends StatelessWidget {
  const _FeedbackPhase({
    required this.pulse,
    required this.content,
    required this.accent,
    required this.isCorrect,
  });

  final Animation<double> pulse;
  final CategoryDemoContent content;
  final Color accent;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: pulse,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.auto_awesome_rounded,
              size: 34,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          isCorrect ? content.feedbackTitle : 'No acertaste esta vez.',
          textAlign: TextAlign.center,
          style: AppTypography.display(26),
        ),
        const SizedBox(height: 12),
        Text(
          isCorrect ? content.feedbackBody : content.feedbackIncorrectBody,
          textAlign: TextAlign.center,
          style: AppTypography.tagline(15).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AnswerRevealPhase extends StatelessWidget {
  const _AnswerRevealPhase({
    required this.pulse,
    required this.content,
    required this.accent,
  });

  final Animation<double> pulse;
  final CategoryDemoContent content;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: pulse,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 34,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Tómate un momento para comparar nuevamente.',
          textAlign: TextAlign.center,
          style: AppTypography.display(24),
        ),
        const SizedBox(height: 20),
        Text(
          'La respuesta correcta era ${content.correctChoiceLabel}.',
          textAlign: TextAlign.center,
          style: AppTypography.cardTitle.copyWith(color: accent),
        ),
        const SizedBox(height: 12),
        Text(
          content.feedbackBody,
          textAlign: TextAlign.center,
          style: AppTypography.tagline(15).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
