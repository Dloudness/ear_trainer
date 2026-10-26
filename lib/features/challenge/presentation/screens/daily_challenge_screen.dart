import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/option_choice_palette.dart';
import '../../../../core/widgets/exercise_typography.dart';
import '../../../../core/widgets/option_choice_card.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../home/presentation/controllers/home_animations.dart';
import '../../../home/presentation/widgets/cinematic_background.dart';
import '../../../home/data/home_mock_data.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with TickerProviderStateMixin {
  late final HomeAnimations _animations;
  String? _playing;
  String? _selected;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _animations = HomeAnimations(vsync: this);
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  void _playSample() {
    setState(() => _playing = 'sample');
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _playing == 'sample') setState(() => _playing = null);
    });
  }

  void _completeChallenge() {
    if (_selected == null) return;
    setState(() => _completed = true);
    MockSession.completeFreeDailyChallenge();
  }

  void _returnHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CinematicBackground(ambient: _animations.ambient),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CinematicNavBar(
                    showHome: MockSession.hasEnteredHub,
                    onHome: () {
                      AppNavigator.goHome(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Desafío diario',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.purpleLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_completed)
                    Text(
                      'Tu oído sigue afinándose.',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    )
                  else
                    ExerciseFocusHeader(
                      instruction: 'Escucha atentamente.',
                      question: HomeMockData.dailyChallengeQuestion,
                      hint: 'Tómate tu tiempo antes de responder.',
                      questionSize: 24,
                      center: false,
                    ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: _completed ? _buildCompleted() : _buildChallenge(),
                  ),
                  if (_completed)
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'VOLVER A HOME',
                        onPressed: _returnHome,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          accent: AppColors.purple,
          padding: const EdgeInsets.all(22),
          onTap: _playSample,
          child: Row(
            children: [
              Icon(
                _playing != null ? Icons.graphic_eq_rounded : Icons.play_circle_outline_rounded,
                size: 22,
                color: AppColors.purpleLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExercisePlaybackHint(
                  playing: _playing != null,
                  idleText: 'Toca para escuchar la muestra',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tu respuesta',
          style: AppTypography.exerciseInstruction,
        ),
        const SizedBox(height: 12),
        _AnswerChip(
          slot: OptionSlot.a,
          label: 'Muddy',
          selected: _selected == 'muddy',
          onTap: () => setState(() => _selected = 'muddy'),
        ),
        const SizedBox(height: 10),
        _AnswerChip(
          slot: OptionSlot.b,
          label: 'Harsh',
          selected: _selected == 'harsh',
          onTap: () => setState(() => _selected = 'harsh'),
        ),
        const Spacer(),
        GradientButton(
          label: 'COMPLETAR',
          compact: true,
          onPressed: _selected == null ? null : _completeChallenge,
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple.withValues(alpha: 0.14),
              border: Border.all(color: AppColors.purpleLight.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.check_rounded, size: 34, color: AppColors.purpleLight),
          ),
          const SizedBox(height: 24),
          Text(
            'Buen oído.',
            style: AppTypography.display(24),
          ),
          const SizedBox(height: 10),
          Text(
            'Detectaste correctamente la resonancia.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            MockSession.isLightMode
                ? 'Guarda tu progreso para seguir entrenando mañana.'
                : 'Tu racha y XP se han actualizado.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.slot,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final OptionSlot slot;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OptionChoiceCard(
      slot: slot,
      label: label,
      selected: selected,
      compact: true,
      onTap: onTap,
    );
  }
}
