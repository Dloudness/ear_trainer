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
import '../../models/eq_practice.dart';
import '../../models/practice_levels.dart';

/// One listen, several answers: advanced EQ bands and pure tones.
class EqBandExerciseScreen extends StatefulWidget {
  const EqBandExerciseScreen({
    super.key,
    required this.exercise,
    required this.pickNext,
    this.routeName = '/module/frecuencias/banda',
    this.ladder,
    this.level,
    this.pink = false,
    this.levelDetail,
  });

  final Exercise exercise;

  /// Draws the following exercise of the same practice at [level],
  /// avoiding [avoidId].
  final Exercise? Function(String? avoidId, int? level) pickNext;
  final String routeName;

  /// Levels of this practice, if it has them, and the one being played.
  /// Answers count toward unlocking the next level.
  final LevelLadder? ladder;
  final int? level;

  /// Pink noise: the level limits the clean reference and picks the
  /// example with or without the clean → EQ → clean transition.
  final bool pink;

  /// What the level asks, shown under the question (null: by drill).
  final String Function(int level)? levelDetail;

  /// Advanced EQ practice for one [source], at [level] when it has levels.
  factory EqBandExerciseScreen.band({
    Key? key,
    required EqSource source,
    required Exercise exercise,
    int? level,
  }) {
    final ladder = level == null ? null : EqPractice.ladder(source);
    return EqBandExerciseScreen(
      key: key,
      exercise: exercise,
      pickNext: (avoidId, level) =>
          EqPractice.pick(source, level: level, avoidId: avoidId),
      ladder: ladder,
      level: ladder == null ? null : level,
      pink: source == EqSource.pink && ladder != null,
      levelDetail: (level) => EqPractice.levelDetail(source, level),
    );
  }

  /// Pure-tone practice for one [drill].
  factory EqBandExerciseScreen.tones({
    Key? key,
    required ToneDrill drill,
    required Exercise exercise,
    int? level,
  }) {
    final ladder = TonePractice.ladder(drill);
    return EqBandExerciseScreen(
      key: key,
      exercise: exercise,
      pickNext: (avoidId, level) =>
          TonePractice.pick(drill, level: level, avoidId: avoidId),
      routeName: '/module/frecuencias/tonos',
      ladder: ladder,
      level: ladder == null ? null : level,
    );
  }

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

  /// The example (processed sound) comes first; the reference is the
  /// second tab.
  String _orbSlot = 'processed';

  /// Level unlocked by the latest answer, if any.
  int? _unlockedLevel;

  bool get _unlimited => _selectedId != null;

  /// Listens to the clean pink noise at this level (null: not pink noise).
  int? get _pinkReferenceListens {
    final level = widget.level;
    return widget.pink && level != null
        ? EqPractice.pinkReferenceListens(level)
        : null;
  }

  /// Example to play: with the clean → EQ → clean transition on the
  /// easier pink-noise levels, the plain processed file otherwise.
  String _examplePath(Exercise exercise) {
    final level = widget.level;
    final sweep = exercise.sweepPath;
    if (widget.pink &&
        level != null &&
        EqPractice.pinkUsesSweep(level) &&
        sweep != null &&
        sweep.isNotEmpty) {
      return sweep;
    }
    return exercise.audio.path;
  }

  int _maxListens(String slot) {
    if (slot == 'reference') {
      return _pinkReferenceListens ?? ExerciseAudioPlayer.maxListens;
    }
    return ExerciseAudioPlayer.maxListens;
  }

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
    final presented = List<ExerciseOption>.of(
      exercise.present(random: _random),
    );
    // Tone and filter answers read best in their natural order (low to
    // high, or higher/lower); band answers are shuffled.
    final ordered =
        exercise.type.startsWith('tone_') || exercise.tags['ordered'] == 'true';
    final options = ordered
        ? (presented..sort(
            (a, b) => exercise.options
                .indexOf(a)
                .compareTo(exercise.options.indexOf(b)),
          ))
        : (presented..shuffle(_random));
    _exercise = exercise;
    _options = options;
    _selectedId = null;
    _showFeedback = false;
    _listens.clear();
    // The example tab is heard first: start loading it now.
    _audioPlayer.preload(_examplePath(exercise));
  }

  bool _canPlay(String slot) {
    final snap = _audioPlayer.snapshot;
    if (_unlimited) return true;
    if (snap.isPlayingOption(slot) || snap.isPausedOption(slot)) return true;
    return (_listens[slot] ?? 0) < _maxListens(slot);
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

  Future<void> _selectSlot(String slot) async {
    if (slot == _orbSlot) return;
    final snap = _audioPlayer.snapshot;
    if (snap.isPlaying || snap.isPaused) await _audioPlayer.stop();
    if (mounted) setState(() => _orbSlot = slot);
  }

  Widget _player(Exercise exercise) {
    final withReference = _hasDistinctReference(exercise);
    final slot = withReference ? _orbSlot : 'processed';
    final path = slot == 'reference'
        ? exercise.referencePath
        : _examplePath(exercise);
    final snap = _audioPlayer.snapshot;
    final active = snap.isActive(slot);

    final pink = widget.pink;

    return OrbPlayer(
      sources: withReference
          ? [
              OrbSource(
                id: 'processed',
                tab: pink ? 'Ecualizado' : 'Procesado',
                title: pink ? 'Ruido rosa ecualizado' : 'Procesado',
              ),
              OrbSource(
                id: 'reference',
                tab: pink ? 'Limpio' : 'Referencia',
                title: pink ? 'Ruido rosa limpio' : 'Referencia',
              ),
            ]
          : const [
              OrbSource(
                id: 'processed',
                tab: 'Ejemplo',
                title: 'Escucha el ejemplo',
              ),
            ],
      selectedId: slot,
      onSelect: (id) => unawaited(_selectSlot(id)),
      isPlaying: snap.isPlayingOption(slot),
      isPaused: snap.isPausedOption(slot),
      progress: active ? snap.progress : 0,
      position: active ? snap.position : null,
      duration: active ? snap.duration : null,
      listensUsed: _unlimited ? null : (_listens[slot] ?? 0),
      maxListens: _maxListens(slot),
      enabled: path != null && path.isNotEmpty && _canPlay(slot),
      onPlayPause: () => unawaited(_play(slot, path)),
    );
  }

  Future<void> _answer(String optionId) async {
    final exercise = _exercise;
    if (exercise == null || _selectedId != null) return;
    setState(() => _selectedId = optionId);
    unawaited(_audioPlayer.stop());
    final correct = optionId == exercise.correct;
    await MockSession.recordExerciseResult(
      exerciseId: exercise.id,
      correct: correct,
    );
    final ladder = widget.ladder, level = widget.level;
    if (ladder != null && level != null) {
      _unlockedLevel = await ladder.record(level: level, correct: correct);
    }
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showFeedback = true);
  }

  /// Shown under the question: the level and what it means.
  String? get _levelNote {
    final ladder = widget.ladder, level = widget.level;
    if (ladder == null || level == null) return null;
    final detail =
        widget.levelDetail?.call(level) ?? TonePractice.levelDetail(level);
    return '${ladder.name(level)} · $detail';
  }

  /// Shown after answering when the answer unlocked a new level.
  String? get _unlockNote {
    final level = _unlockedLevel;
    return level == null ? null : widget.ladder?.unlockedNote(level);
  }

  Future<void> _goNext() async {
    unawaited(_audioPlayer.stop());
    // Registered at the limit: the gate already went home. "Ahora no":
    // stay on the result.
    if (!await ensureCanPractice(context) || !mounted) return;
    // A newly earned level is used only with Premium.
    final level =
        (MockSession.hasPremium ? _unlockedLevel : null) ?? widget.level;
    final next = widget.pickNext(_exercise?.id, level);
    if (!mounted) return;
    if (next == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: RouteSettings(name: widget.routeName),
        screen: EqBandExerciseScreen(
          exercise: next,
          pickNext: widget.pickNext,
          routeName: widget.routeName,
          ladder: widget.ladder,
          level: level,
          pink: widget.pink,
          levelDetail: widget.levelDetail,
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
                      note: _unlockNote,
                      player: _player(exercise),
                    )
                  : _ListenView(
                      exercise: exercise,
                      options: _options,
                      selectedId: _selectedId,
                      withReference: _hasDistinctReference(exercise),
                      levelNote: _levelNote,
                      player: _player(exercise),
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
    // At the level without reference, the clean noise appears only after
    // answering, to compare.
    if (_pinkReferenceListens == 0 && !_unlimited) return false;
    final reference = exercise.referencePath;
    return reference != null &&
        reference.isNotEmpty &&
        reference != exercise.audio.path;
  }
}

class _ListenView extends StatelessWidget {
  const _ListenView({
    required this.exercise,
    required this.options,
    required this.selectedId,
    required this.withReference,
    required this.player,
    required this.onSelect,
    this.levelNote,
  });

  final Exercise exercise;
  final List<ExerciseOption> options;
  final String? selectedId;
  final bool withReference;
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
          hint: switch (exercise.type) {
            'tone_frequency' => 'Un solo tono, sin nada más.',
            'tone_compare' => 'El primer tono es la referencia.',
            _ when exercise.tags['skill'] == 'filter' =>
              'El nivel general es el mismo. Solo cambia el filtro.',
            _ when withReference =>
              'El nivel general es el mismo. Cambia una sola banda.',
            _ => 'Identifica la frecuencia y el ajuste de este ejemplo.',
          },
          questionSize: 24,
        ),
        const SizedBox(height: 24),
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
    final extra = note;
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
        if (extra != null) ...[
          const SizedBox(height: 16),
          Text(
            extra,
            textAlign: TextAlign.center,
            style: AppTypography.tagline(15).copyWith(color: AppColors.cyan),
          ),
        ],
        const SizedBox(height: 28),
        player,
      ],
    );
  }
}
