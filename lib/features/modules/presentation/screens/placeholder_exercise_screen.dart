import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/exercise_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../home/presentation/controllers/home_animations.dart';
import '../../../home/presentation/widgets/cinematic_background.dart';
import '../../models/placeholder_exercise_args.dart';

class PlaceholderExerciseScreen extends StatefulWidget {
  const PlaceholderExerciseScreen({super.key, required this.args});

  final PlaceholderExerciseArgs args;

  @override
  State<PlaceholderExerciseScreen> createState() => _PlaceholderExerciseScreenState();
}

class _PlaceholderExerciseScreenState extends State<PlaceholderExerciseScreen>
    with TickerProviderStateMixin {
  late final HomeAnimations _animations;
  bool _playing = false;

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
    setState(() => _playing = true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CinematicBackground(ambient: _animations.ambient),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CinematicNavBar(
                    showHome: MockSession.hasEnteredHub,
                    onHome: () => AppNavigator.goHome(context),
                  ),
                  const Spacer(flex: 2),
                  FadeInSection(
                    child: Column(
                      children: [
                        if (args.moduleTitle != null) ...[
                          Text(
                            args.moduleTitle!,
                            style: AppTypography.caption.copyWith(
                              color: args.accent,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ExerciseFocusHeader(
                            instruction: 'Escucha atentamente.',
                            question: args.title,
                            hint: 'Tómate tu tiempo antes de responder.',
                            questionSize: 24,
                          ),
                        ),
                        const SizedBox(height: 36),
                        BreathingGlow(
                          color: args.accent,
                          minOpacity: 0.06,
                          maxOpacity: 0.12,
                          child: GlassPanel(
                            accent: args.accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 36,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  child: Icon(
                                    _playing
                                        ? Icons.graphic_eq_rounded
                                        : Icons.hearing_rounded,
                                    key: ValueKey(_playing),
                                    size: 44,
                                    color: args.accent,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ExercisePlaybackHint(playing: _playing),
                                const SizedBox(height: 28),
                                GradientButton(
                                  label: 'ESCUCHAR',
                                  compact: true,
                                  icon: Icons.play_arrow_rounded,
                                  emphasized: true,
                                  onPressed: _playSample,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    args.comingSoon,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
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
}
