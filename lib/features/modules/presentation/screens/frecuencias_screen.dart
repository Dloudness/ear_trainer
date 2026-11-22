import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/training_context.dart';
import '../widgets/module_screen_layout.dart';
import '../widgets/training_context_dialog.dart';
import 'eq_advanced_screen.dart';
import 'eq_initial_screen.dart';

class FrecuenciasScreen extends StatefulWidget {
  const FrecuenciasScreen({super.key});

  @override
  State<FrecuenciasScreen> createState() => _FrecuenciasScreenState();
}

class _FrecuenciasScreenState extends State<FrecuenciasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offerContext();
    });
  }

  Future<void> _offerContext() async {
    if (!mounted || MockSession.hasSeenTrainingContext(TrainingContextIds.eq)) {
      return;
    }
    await showTrainingContext(context, TrainingContextIds.eq, required: true);
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
          onOpen: () =>
              _open(const EqInitialScreen(), '/module/frecuencias/inicial'),
        ),
        _LevelCard(
          title: 'Avanzado',
          detail:
              'Identifica la frecuencia y el ajuste en el ruido rosa.',
          onOpen: () =>
              _open(const EqAdvancedScreen(), '/module/frecuencias/avanzado'),
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
