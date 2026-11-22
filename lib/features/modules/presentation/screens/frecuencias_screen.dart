import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../demo/models/demo_experience_args.dart';
import '../../../onboarding/models/onboarding_option.dart';
import '../../data/training_context.dart';
import '../../models/eq_practice.dart';
import '../widgets/module_screen_layout.dart';
import '../widgets/training_context_dialog.dart';
import 'eq_advanced_screen.dart';
import 'tone_screen.dart';

class FrecuenciasScreen extends StatefulWidget {
  const FrecuenciasScreen({super.key});

  @override
  State<FrecuenciasScreen> createState() => _FrecuenciasScreenState();
}

class _FrecuenciasScreenState extends State<FrecuenciasScreen> {
  /// Inicial: explanation, then straight into a random unlocked comparison.
  Future<void> _startInitial() async {
    if (!await ensureCanPractice(context) || !mounted) return;
    final started = await showTrainingContext(
      context,
      TrainingContextIds.eq,
      actionLabel: 'ESCUCHAR',
      shortWhenSeen: true,
    );
    if (!mounted || !started) return;

    final index = EqInitialPractice.pickIndex();
    if (index == null) {
      final registered = await promptRegister(context);
      if (registered && mounted) unawaited(_startInitial());
      return;
    }
    await Navigator.pushNamed(
      context,
      AppRoutes.demo,
      arguments: DemoExperienceArgs(
        category: OnboardingOption.ecualizacionFrecuencias,
        exerciseIndex: index,
        practice: true,
      ),
    );
  }

  Future<void> _open(Widget screen, String routeName) {
    return Navigator.push(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: RouteSettings(name: routeName),
        screen: screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScreenLayout(
      title: 'Frecuencias',
      subtitle:
          'Elige un nivel. Inicial reconoce el cambio; Avanzado identifica la banda.',
      header: const TrainingContextLink(contextId: TrainingContextIds.eq),
      children: [
        _LevelCard(
          title: 'Inicial',
          detail:
              'Graves, agudos y una guitarra fuera de balance, en lenguaje cotidiano.',
          onOpen: () => unawaited(_startInitial()),
        ),
        _LevelCard(
          title: 'Avanzado',
          detail:
              'Identifica la frecuencia y el ajuste en el ruido rosa.',
          onOpen: () =>
              _open(const EqAdvancedScreen(), '/module/frecuencias/avanzado'),
        ),
        _LevelCard(
          title: 'Tonos puros',
          detail:
              'Elige: reconocer la frecuencia de un tono o decir si el segundo sube o baja.',
          onOpen: () =>
              _open(const ToneScreen(), '/module/frecuencias/tonos-puros'),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.title,
    required this.detail,
    required this.onOpen,
  });

  final String title;
  final String detail;
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
            title,
            style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: AppTypography.caption.copyWith(fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 10),
          GradientButton(
            label: 'EMPEZAR',
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
