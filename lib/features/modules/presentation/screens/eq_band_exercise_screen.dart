import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/audio/exercise_audio_player.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/option_choice_palette.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/exercise_listen_card.dart';
import '../../../../core/widgets/exercise_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/option_choice_card.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../exercises/models/exercise.dart';
import '../../models/eq_practice.dart';

class EqBandExerciseScreen extends StatefulWidget {
  const EqBandExerciseScreen({
    super.key,
    required this.source,
    required this.exercise,
  });

  final EqSource source;
  final Exercise exercise;

  @override
  State<EqBandExerciseScreen> createState() => _EqBandExerciseScreenState();
}

class _EqBandExerciseScreenState extends State<EqBandExerciseScreen> {
  final ExerciseAudioPlayer _audioPlayer = ExerciseAudioPlayer();
  final Random _random = Random();

  Exercise? _exercise;
  List<ExerciseOption> _options = const [];
  String? _selectedId;
  var _showFeedback = false;
  final Map<String, int> _listens = {};

  bool get _unlimited => _selectedId != null;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlaybackStateChanged = () {
      if (mounted) setState(() {});
    };
    _load(widget.exercise);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _load(Exercise exercise) {
    final options = List<ExerciseOption>.of(exercise.options)..shuffle(_random);
    _exercise = exercise;
    _options = options;
    _selectedId = null;
    _showFeedback = false;
    _listens.clear();
  }

  bool _canPlay(String slot) {
    final snap = _audioPlayer.snapshot;
    if (_unlimited) return true;
    if (snap.isPlayingOption(slot) || snap.isPausedOption(slot)) return true;
    return (_listens[slot] ?? 0) < ExerciseAudioPlayer.maxListens;
  }

  Future<void> _play(String slot, String? path) async {
    if (path == null || path.isEmpty || !_canPlay(slot)) return;
    try {
      final action = await _audioPlayer.playOption(slot, path);
      if (!mounted || action != ListenAction.started || _unlimited) return;
      setState(() => _listens[slot] = (_listens[slot] ?? 0) + 1);
    } catch (error) {
      debugPrint(
        'ExerciseRepository: audio inexistente en ${_exercise?.id}: $path ($error)',
      );
    }
  }

  Future<void> _seek(String slot, String? path, double fraction) async {
    if (path == null || path.isEmpty || !_canPlay(slot)) return;
    try {
      final action = await _audioPlayer.startIfIdle(slot, path);
      if (action == ListenAction.started && !_unlimited && mounted) {
        setState(() => _listens[slot] = (_listens[slot] ?? 0) + 1);
      }
      await _audioPlayer.seekToFraction(fraction);
    } catch (error) {
      debugPrint('ExerciseRepository: no se pudo buscar en el audio ($error)');
    }
  }

  Widget _listenCard({
    required String slot,
    required OptionSlot color,
    required String label,
    required String? path,
  }) {
    final snap = _audioPlayer.snapshot;
    return ExerciseListenCard(
      slot: color,
      label: label,
      isPlaying: snap.isPlayingOption(slot),
      isPaused: snap.isPausedOption(slot),
      progress: snap.isActive(slot) ? snap.progress : 0,
      listensUsed: _unlimited ? null : (_listens[slot] ?? 0),
      enabled: path != null && _canPlay(slot),
      onPlayPause: () => unawaited(_play(slot, path)),
      onSeek: (fraction) => unawaited(_seek(slot, path, fraction)),
    );
  }

  Future<void> _answer(String optionId) async {
    final exercise = _exercise;
    if (exercise == null || _selectedId != null) return;
    setState(() => _selectedId = optionId);
    unawaited(_audioPlayer.stop());
    await MockSession.recordExerciseResult(
      exerciseId: exercise.id,
      correct: optionId == exercise.correct,
    );
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showFeedback = true);
  }

  Future<void> _goNext() async {
    final next = EqPractice.pick(widget.source, avoidId: _exercise?.id);
    if (!mounted) return;
    if (next == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/frecuencias/banda'),
        screen: EqBandExerciseScreen(source: widget.source, exercise: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;
    return CinematicScreen(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            CinematicNavBar(
              backLabel: 'Back',
              onBack: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: exercise == null
                  ? const Center(
                      child: Text('Este ejercicio no está disponible.'),
                    )
                  : _showFeedback
                  ? _FeedbackView(
                      exercise: exercise,
                      correct: _selectedId == exercise.correct,
                      reference: _referencePlayer(exercise),
                      example: _examplePlayer(exercise),
                    )
                  : _ListenView(
                      exercise: exercise,
                      options: _options,
                      selectedId: _selectedId,
                      reference: _referencePlayer(exercise),
                      example: _examplePlayer(exercise),
                      onSelect: (id) => unawaited(_answer(id)),
                    ),
            ),
            if (exercise != null && _showFeedback)
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'SIGUIENTE EJERCICIO',
                  onPressed: () => unawaited(_goNext()),
                ),
              )
            else
              const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  bool _hasDistinctReference(Exercise exercise) {
    final reference = exercise.referencePath;
    return reference != null &&
        reference.isNotEmpty &&
        reference != exercise.audio.path;
  }

  Widget? _referencePlayer(Exercise exercise) {
    if (!_hasDistinctReference(exercise)) return null;
    return _listenCard(
      slot: 'reference',
      color: OptionSlot.a,
      label: 'REFERENCIA',
      path: exercise.referencePath,
    );
  }

  Widget _examplePlayer(Exercise exercise) {
    return _listenCard(
      slot: 'processed',
      color: OptionSlot.b,
      label: _hasDistinctReference(exercise) ? 'PROCESADO' : 'ESCUCHAR',
      path: exercise.audio.path,
    );
  }
}

class _ListenView extends StatelessWidget {
  const _ListenView({
    required this.exercise,
    required this.options,
    required this.selectedId,
    required this.reference,
    required this.example,
    required this.onSelect,
  });

  final Exercise exercise;
  final List<ExerciseOption> options;
  final String? selectedId;
  final Widget? reference;
  final Widget example;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final intro = exercise.intro;

    return ListView(
      children: [
        if (intro != null && intro.isNotEmpty) ...[
          Text(
            intro,
            textAlign: TextAlign.center,
            style: AppTypography.tagline(
              15,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
        ],
        ExerciseFocusHeader(
          instruction: 'Escucha atentamente.',
          question: exercise.question,
          hint: reference == null
              ? 'Identifica la frecuencia y el ajuste de este ejemplo.'
              : 'El nivel general es el mismo. Cambia una sola banda.',
          questionSize: 24,
        ),
        const SizedBox(height: 28),
        if (reference != null) ...[reference!, const SizedBox(height: 12)],
        example,
        const SizedBox(height: 28),
        Text('Tu respuesta', style: AppTypography.exerciseInstruction),
        const SizedBox(height: 12),
        for (var i = 0; i < options.length; i++) ...[
          OptionChoiceCard(
            slot: OptionSlot.values[i],
            label: options[i].label,
            selected: selectedId == options[i].id,
            compact: true,
            onTap: () => onSelect(options[i].id),
          ),
          if (i != options.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        Text(
          'Tómate tu tiempo antes de responder.',
          textAlign: TextAlign.center,
          style: AppTypography.exerciseHint,
        ),
      ],
    );
  }
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({
    required this.exercise,
    required this.correct,
    required this.reference,
    required this.example,
  });

  final Exercise exercise;
  final bool correct;
  final Widget? reference;
  final Widget example;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Icon(
          correct ? Icons.check_rounded : Icons.auto_awesome_rounded,
          size: 34,
          color: AppColors.cyan,
        ),
        const SizedBox(height: 28),
        Text(
          correct ? 'Buen oído.' : 'No acertaste esta vez.',
          textAlign: TextAlign.center,
          style: AppTypography.display(26),
        ),
        const SizedBox(height: 12),
        Text(
          exercise.explanation,
          textAlign: TextAlign.center,
          style: AppTypography.tagline(
            15,
          ).copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        if (reference != null) ...[reference!, const SizedBox(height: 12)],
        example,
      ],
    );
  }
}
