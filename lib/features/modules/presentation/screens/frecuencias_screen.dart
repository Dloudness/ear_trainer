import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/models/onboarding_option.dart';
import '../../data/training_context.dart';
import '../../models/module_exercise_catalog.dart';
import '../widgets/module_exercise_list_card.dart';
import '../widgets/module_screen_layout.dart';
import '../widgets/training_context_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final exercises = ModuleExerciseCatalog.forCategory(
      OnboardingOption.ecualizacionFrecuencias,
    );

    return ModuleScreenLayout(
      title: 'Frecuencias',
      subtitle: 'Detecta rangos, balance tonal y fatiga auditiva.',
      header: const TrainingContextLink(contextId: TrainingContextIds.eq),
      children: [
        for (final entry in exercises)
          ModuleExerciseListCard(entry: entry, accent: AppColors.cyan),
      ],
    );
  }
}
