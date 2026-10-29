import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../models/musical_sections.dart';
import '../widgets/module_screen_layout.dart';
import 'musical_exercise_screen.dart';

class MusicalSectionScreen extends StatelessWidget {
  const MusicalSectionScreen({
    super.key,
    required this.sectionId,
  });

  final MusicalSectionId sectionId;

  @override
  Widget build(BuildContext context) {
    final section = MusicalSections.byId(sectionId);
    final exercises = section?.exercises ?? const [];

    return ModuleScreenLayout(
      title: section?.title ?? 'Entrenamiento Musical',
      subtitle: 'Ordenados de más fácil a más difícil.',
      children: [
        for (var i = 0; i < exercises.length; i++)
          _SectionExerciseCard(
            index: i,
            question: exercises[i].question,
            difficulty: exercises[i].difficulty,
            onListen: () {
              Navigator.push(
                context,
                AppTransitions.cinematicRoute<void>(
                  settings: const RouteSettings(name: '/module/musical/exercise'),
                  screen: MusicalExerciseScreen(
                    sectionId: sectionId,
                    exerciseIndex: i,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SectionExerciseCard extends StatelessWidget {
  const _SectionExerciseCard({
    required this.index,
    required this.question,
    required this.difficulty,
    required this.onListen,
  });

  final int index;
  final String question;
  final String difficulty;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: MusicalSections.accent,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ejercicio ${index + 1} · ${_difficultyLabel(difficulty)}',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: MusicalSections.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question,
            style: AppTypography.cardTitle.copyWith(fontSize: 14, height: 1.25),
          ),
          const SizedBox(height: 10),
          GradientButton(
            label: 'ESCUCHAR',
            compact: true,
            dense: true,
            icon: Icons.play_arrow_rounded,
            emphasized: true,
            onPressed: onListen,
          ),
        ],
      ),
    );
  }
}

String _difficultyLabel(String difficulty) {
  return switch (difficulty) {
    'beginner' => 'Principiante',
    'intermediate' => 'Intermedio',
    'advanced' => 'Avanzado',
    _ => difficulty,
  };
}
