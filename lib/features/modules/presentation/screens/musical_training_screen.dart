import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../models/musical_sections.dart';
import '../widgets/module_screen_layout.dart';
import 'musical_section_screen.dart';

class MusicalTrainingScreen extends StatelessWidget {
  const MusicalTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = MusicalSections.all();

    return ModuleScreenLayout(
      title: 'Entrenamiento Musical',
      subtitle: 'Intervalos, acordes y percepción armónica.',
      children: [
        if (sections.isEmpty)
          Text(
            'No hay ejercicios con audio disponible.',
            style: AppTypography.tagline(15),
          ),
        for (final section in sections)
          GlassPanel(
            accent: MusicalSections.accent,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  '${section.exercises.length} ejercicios',
                  style: AppTypography.caption.copyWith(
                    color: MusicalSections.accent,
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'VER LISTA',
                  compact: true,
                  icon: Icons.queue_music_rounded,
                  emphasized: true,
                  onPressed: () {
                    Navigator.push(
                      context,
                      AppTransitions.cinematicRoute<void>(
                        settings: const RouteSettings(name: '/module/musical/section'),
                        screen: MusicalSectionScreen(sectionId: section.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
