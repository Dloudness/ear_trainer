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

class EqAdvancedScreen extends StatelessWidget {
  const EqAdvancedScreen({super.key});

  Future<void> _open(BuildContext context, EqSource source) async {
    if (!await ensureCanPractice(context) || !context.mounted) return;
    final started = await showTrainingContext(
      context,
      TrainingContextIds.eq,
      actionLabel: 'ESCUCHAR',
      shortWhenSeen: true,
    );
    if (!started || !context.mounted) return;
    final exercise = EqPractice.pick(source);
    if (exercise == null || !context.mounted) return;
    await Navigator.push(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/frecuencias/banda'),
        screen: EqBandExerciseScreen(source: source, exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScreenLayout(
      title: 'Avanzado',
      subtitle:
          'Identifica la frecuencia y el nivel. El cambio de tono ya está en el ejemplo.',
      children: [
        for (final source in EqSource.values)
          if (EqPractice.of(source).isNotEmpty)
            _SourceCard(source: source, onOpen: () => _open(context, source)),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.onOpen});

  final EqSource source;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: AppColors.cyan,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EqPractice.title(source),
            style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text(
            EqPractice.detail(source),
            style: AppTypography.caption.copyWith(fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 10),
          GradientButton(
            label: 'PRACTICAR',
            compact: true,
            dense: true,
            icon: Icons.play_arrow_rounded,
            emphasized: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
