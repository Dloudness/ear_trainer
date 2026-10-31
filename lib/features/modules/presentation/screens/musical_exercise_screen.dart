import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/audio/exercise_audio_player.dart';
import '../../../../core/auth/account_prompt.dart';
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
import '../../models/musical_pool.dart';
import '../../models/musical_sections.dart';
import '../widgets/training_context_dialog.dart';

class MusicalExerciseScreen extends StatefulWidget {
  const MusicalExerciseScreen({
    super.key,
    required this.pool,
    required this.exercise,
  });

  final MusicalPool pool;
  final Exercise exercise;

  @override
  State<MusicalExerciseScreen> createState() => _MusicalExerciseScreenState();
}

class _MusicalExerciseScreenState extends State<MusicalExerciseScreen> {
  final ExerciseAudioPlayer _audioPlayer = ExerciseAudioPlayer();
  final Random _random = Random();

  Exercise? _exercise;
  List<ExerciseOption> _options = const [];
  String? _selectedId;
  var _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlaybackStateChanged = () {
      if (mounted) setState(() {});
    };
    _exercise = widget.exercise;
    _options = _rolledOptions(widget.exercise);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  List<ExerciseOption> _rolledOptions(Exercise exercise) {
    final presented = exercise.present(random: _random);
    if (exercise.access == 'free') return List<ExerciseOption>.of(presented);
    return List<ExerciseOption>.of(presented)..shuffle(_random);
  }

  Future<void> _play() async {
    final exercise = _exercise;
    if (exercise == null) return;
    final path = exercise.audio.path;
    try {
      await _audioPlayer.playOption('listen', path);
    } catch (error) {
      debugPrint(
        'ExerciseRepository: audio inexistente en ${exercise.id}: $path ($error)',
      );
    }
  }

  Future<void> _replay() async {
    final exercise = _exercise;
    if (exercise == null) return;
    final path = exercise.audio.path;
    try {
      await _audioPlayer.replayOption('listen', path);
    } catch (error) {
      debugPrint(
        'ExerciseRepository: audio inexistente en ${exercise.id}: $path ($error)',
      );
    }
  }

  Future<void> _answer(String optionId) async {
    final exercise = _exercise;
    if (exercise == null || _selectedId != null) return;
    setState(() => _selectedId = optionId);
    await _audioPlayer.stop();
    await MockSession.recordExerciseResult(
      exerciseId: exercise.id,
      correct: optionId == exercise.correct,
    );
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showFeedback = true);
  }

  Future<void> _goNext() async {
    var next = MusicalPools.pick(widget.pool, avoidId: _exercise?.id);
    if (next == null && MusicalPools.needsAccountPrompt(widget.pool)) {
      final registered = await promptRegister(context);
      if (!registered || !mounted) return;
      next = MusicalPools.pick(widget.pool, avoidId: _exercise?.id);
    }
    if (!mounted) return;
    if (next == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/musical/exercise'),
        screen: MusicalExerciseScreen(pool: widget.pool, exercise: next),
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
            TrainingContextLink(pool: widget.pool),
            const SizedBox(height: 8),
            Expanded(
              child: exercise == null
                  ? const Center(child: Text('Este ejercicio no está disponible.'))
                  : _showFeedback
                      ? _FeedbackView(
                          exercise: exercise,
                          correct: _selectedId == exercise.correct,
                        )
                      : _ListenView(
                          exercise: exercise,
                          options: _options,
                          selectedId: _selectedId,
                          isPlaying: _audioPlayer.snapshot.isPlayingOption('listen'),
                          isPaused: _audioPlayer.snapshot.isPausedOption('listen'),
                          progress: _audioPlayer.snapshot.isActive('listen')
                              ? _audioPlayer.snapshot.progress
                              : 0,
                          onPlay: () => unawaited(_play()),
                          onReplay: () => unawaited(_replay()),
                          onSeek: (fraction) =>
                              unawaited(_audioPlayer.seekToFraction(fraction)),
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
}

class _ListenView extends StatelessWidget {
  const _ListenView({
    required this.exercise,
    required this.options,
    required this.selectedId,
    required this.isPlaying,
    required this.isPaused,
    required this.progress,
    required this.onPlay,
    required this.onReplay,
    required this.onSeek,
    required this.onSelect,
  });

  final Exercise exercise;
  final List<ExerciseOption> options;
  final String? selectedId;
  final bool isPlaying;
  final bool isPaused;
  final double progress;
  final VoidCallback onPlay;
  final VoidCallback onReplay;
  final ValueChanged<double> onSeek;
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
            style: AppTypography.tagline(15).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
        ExerciseFocusHeader(
          instruction: 'Escucha atentamente.',
          question: exercise.question,
          hint: 'Escucha el audio y elige una opción.',
          questionSize: 24,
        ),
        const SizedBox(height: 28),
        ExerciseListenCard(
          slot: OptionSlot.a,
          label: 'ESCUCHAR',
          isPlaying: isPlaying,
          isPaused: isPaused,
          progress: progress,
          onPlayPause: onPlay,
          onSeek: onSeek,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: GradientButton(
            label: 'REPETIR',
            compact: true,
            translucent: true,
            icon: Icons.replay_rounded,
            onPressed: onReplay,
          ),
        ),
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
  });

  final Exercise exercise;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final accent = MusicalSections.accent;
    final tip = exercise.tip;

    return ListView(
      children: [
        const SizedBox(height: 24),
        Icon(
          correct ? Icons.check_rounded : Icons.auto_awesome_rounded,
          size: 34,
          color: accent,
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
          style: AppTypography.tagline(15).copyWith(color: AppColors.textSecondary),
        ),
        if (tip != null && tip.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Pista',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            textAlign: TextAlign.center,
            style: AppTypography.tagline(15).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
