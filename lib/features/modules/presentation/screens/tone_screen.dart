import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/training_context.dart';
import '../../models/eq_practice.dart';
import '../widgets/module_screen_layout.dart';
import '../widgets/training_context_dialog.dart';
import 'eq_band_exercise_screen.dart';

/// Tonos puros: the listener picks which drill to practice.
class ToneScreen extends StatelessWidget {
  const ToneScreen({super.key});

  Future<void> _open(BuildContext context, ToneDrill drill) async {
    if (!await ensureCanPractice(context) || !context.mounted) return;
    final started = await showTrainingContext(
      context,
      TrainingContextIds.tones,
      actionLabel: 'ESCUCHAR',
      shortWhenSeen: true,
    );
    if (!started || !context.mounted) return;
    final exercise = TonePractice.pick(drill);
    if (exercise == null || !context.mounted) return;
    await Navigator.push(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/frecuencias/tonos'),
        screen: EqBandExerciseScreen.tones(drill: drill, exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScreenLayout(
      title: 'Tonos puros',
      subtitle: 'Elige qué quieres entrenar.',
      children: [
        for (final drill in ToneDrill.values)
          if (TonePractice.of(drill).isNotEmpty)
            GlassPanel(
              accent: AppColors.cyan,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TonePractice.title(drill),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    TonePractice.detail(drill),
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GradientButton(
                    label: 'PRACTICAR',
                    compact: true,
                    dense: true,
                    icon: Icons.play_arrow_rounded,
                    emphasized: true,
                    onPressed: () => _open(context, drill),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
