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
import '../../../../core/widgets/exercise_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/option_choice_card.dart';
import '../../../../core/widgets/orb_player.dart';
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
  String _orbSlot = 'reference';

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
        : exercise.audio.path;
    final snap = _audioPlayer.snapshot;
    final active = snap.isActive(slot);

    return OrbPlayer(
      sources: withReference
          ? const [
              OrbSource(id: 'reference', tab: 'Referencia', title: 'Referencia'),
              OrbSource(id: 'processed', tab: 'Procesado', title: 'Procesado'),
            ]
          : const [
              OrbSource(id: 'processed', tab: 'Ejemplo', title: 'Escucha el ejemplo'),
            ],
      selectedId: slot,
      onSelect: (id) => unawaited(_selectSlot(id)),
      isPlaying: snap.isPlayingOption(slot),
      isPaused: snap.isPausedOption(slot),
      progress: active ? snap.progress : 0,
      position: active ? snap.position : null,
      duration: active ? snap.duration : null,
      listensUsed: _unlimited ? null : (_listens[slot] ?? 0),
      enabled: path != null && path.isNotEmpty && _canPlay(slot),
      onPlayPause: () => unawaited(_play(slot, path)),
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
                      player: _player(exercise),
                    )
                  : _ListenView(
                      exercise: exercise,
                      options: _options,
                      selectedId: _selectedId,
                      withReference: _hasDistinctReference(exercise),
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
  });

  final Exercise exercise;
  final List<ExerciseOption> options;
  final String? selectedId;
  final bool withReference;
  final Widget player;
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
          hint: withReference
              ? 'El nivel general es el mismo. Cambia una sola banda.'
              : 'Identifica la frecuencia y el ajuste de este ejemplo.',
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
  });

  final Exercise exercise;
  final bool correct;
  final Widget player;

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
        player,
      ],
    );
  }
}
