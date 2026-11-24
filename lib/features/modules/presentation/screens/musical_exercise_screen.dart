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
import '../../../../core/widgets/exercise_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/option_choice_card.dart';
import '../../../../core/widgets/orb_player.dart';
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
    this.level,
  });

  final MusicalPool pool;
  final Exercise exercise;

  /// Level being played when the pool has levels (tuning in context).
  final int? level;

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
  var _listens = 0;

  bool get _unlimited => _selectedId != null;

  bool get _canPlay {
    final snap = _audioPlayer.snapshot;
    if (_unlimited) return true;
    if (snap.isPlayingOption('listen') || snap.isPausedOption('listen')) {
      return true;
    }
    return _listens < ExerciseAudioPlayer.maxListens;
  }

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
    if (exercise.access == 'free' || exercise.type == 'pitch_context') {
      // Free lessons and "Nota 1-4" / "Afinada, Alta, Baja" read in order.
      return List<ExerciseOption>.of(presented);
    }
    return List<ExerciseOption>.of(presented)..shuffle(_random);
  }

  Future<void> _play() async {
    final exercise = _exercise;
    if (exercise == null || !_canPlay) return;
    final path = exercise.audio.path;
    try {
      final action = await _audioPlayer.playOption('listen', path);
      if (!mounted || action != ListenAction.started || _unlimited) return;
      setState(() => _listens += 1);
    } catch (error) {
      debugPrint(
        'ExerciseRepository: audio inexistente en ${exercise.id}: $path ($error)',
      );
    }
  }

  Widget _listenCard() {
    final snap = _audioPlayer.snapshot;
    final active = snap.isActive('listen');
    return OrbPlayer(
      sources: const [
        OrbSource(id: 'listen', tab: 'Escuchar', title: 'Escucha con atención'),
      ],
      selectedId: 'listen',
      onSelect: (_) {},
      isPlaying: snap.isPlayingOption('listen'),
      isPaused: snap.isPausedOption('listen'),
      progress: active ? snap.progress : 0,
      position: active ? snap.position : null,
      duration: active ? snap.duration : null,
      listensUsed: _unlimited ? null : _listens,
      enabled: _canPlay,
      onPlayPause: () => unawaited(_play()),
    );
  }

  Future<void> _answer(String optionId) async {
    final exercise = _exercise;
    if (exercise == null || _selectedId != null) return;
    setState(() => _selectedId = optionId);
    await _audioPlayer.stop();
    final correct = optionId == exercise.correct;
    await MockSession.recordExerciseResult(
      exerciseId: exercise.id,
      correct: correct,
    );
    final ladder = MusicalPools.ladder(widget.pool), level = widget.level;
    if (ladder != null && level != null) {
      _unlockedLevel = await ladder.record(level: level, correct: correct);
    }
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showFeedback = true);
  }

  /// Level unlocked by the latest answer, if any.
  int? _unlockedLevel;

  String? get _levelNote {
    final ladder = MusicalPools.ladder(widget.pool), level = widget.level;
    if (ladder == null || level == null) return null;
    return '${ladder.name(level)} · ${MusicalPools.levelDetail(level)}';
  }

  Future<void> _goNext() async {
    if (!await ensureCanPractice(context) || !mounted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final level = _unlockedLevel ?? widget.level;
    var next = MusicalPools.pick(
      widget.pool,
      level: level,
      avoidId: _exercise?.id,
    );
    if (next == null && MusicalPools.needsAccountPrompt(widget.pool)) {
      final registered = await promptRegister(context);
      if (!registered || !mounted) return;
      next = MusicalPools.pick(
        widget.pool,
        level: level,
        avoidId: _exercise?.id,
      );
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
        screen: MusicalExerciseScreen(
          pool: widget.pool,
          exercise: next,
          level: level,
        ),
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
            TrainingContextLink(contextId: MusicalPools.contextId(widget.pool)),
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
                      note: _unlockedLevel == null
                          ? null
                          : MusicalPools.ladder(
                              widget.pool,
                            )?.unlockedNote(_unlockedLevel!),
                      player: _listenCard(),
                    )
                  : _ListenView(
                      exercise: exercise,
                      options: _options,
                      selectedId: _selectedId,
                      levelNote: _levelNote,
                      player: _listenCard(),
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
    required this.player,
    required this.onSelect,
    this.levelNote,
  });

  final Exercise exercise;
  final List<ExerciseOption> options;
  final String? selectedId;
  final Widget player;
  final ValueChanged<String> onSelect;
  final String? levelNote;

  @override
  Widget build(BuildContext context) {
    final intro = exercise.intro;
    final note = levelNote;

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
          SizedBox(height: note == null ? 20 : 8),
        ],
        if (note != null) ...[
          Text(
            note,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.cyan),
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
        player,
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
    required this.player,
    this.note,
  });

  final Exercise exercise;
  final bool correct;
  final Widget player;

  /// Extra line, e.g. a newly unlocked level.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final accent = MusicalSections.accent;
    final tip = exercise.tip;
    final extra = note;

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
          style: AppTypography.tagline(
            15,
          ).copyWith(color: AppColors.textSecondary),
        ),
        if (extra != null) ...[
          const SizedBox(height: 16),
          Text(
            extra,
            textAlign: TextAlign.center,
            style: AppTypography.tagline(15).copyWith(color: AppColors.cyan),
          ),
        ],
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
            style: AppTypography.tagline(
              15,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 28),
        player,
      ],
    );
  }
}
