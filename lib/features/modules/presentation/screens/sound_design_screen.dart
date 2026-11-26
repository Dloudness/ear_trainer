import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../models/sound_design_practice.dart';
import '../widgets/module_screen_layout.dart';
import 'eq_band_exercise_screen.dart';

/// Diseño sonoro (Premium): one card per practice. For now every practice
/// is level Básico.
class SoundDesignScreen extends StatelessWidget {
  const SoundDesignScreen({super.key});

  static const accent = Color(0xFFFB923C);

  Future<void> _open(BuildContext context, SoundDesignDrill drill) async {
    if (!await ensureCanPractice(context) || !context.mounted) return;
    final exercise = SoundDesignPractice.pick(drill);
    if (exercise == null) return;
    await Navigator.push(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/diseno-sonoro/practica'),
        screen: EqBandExerciseScreen.soundDesign(drill: drill, exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScreenLayout(
      title: 'Diseño sonoro',
      subtitle: 'Sonido para cine, video y podcast. Nivel Básico.',
      children: [
        for (final drill in SoundDesignDrill.values)
          if (SoundDesignPractice.of(drill).isNotEmpty)
            GlassPanel(
              accent: accent,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SoundDesignPractice.title(drill),
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    SoundDesignPractice.detail(drill),
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
        if (SoundDesignDrill.values.every(
          (drill) => SoundDesignPractice.of(drill).isEmpty,
        ))
          Text(
            'Los ejercicios de Diseño sonoro son parte de Premium.',
            style: AppTypography.caption.copyWith(color: AppColors.amber),
          ),
      ],
    );
  }
}
