import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../modules/models/module_exercise_catalog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../home/presentation/widgets/module_neon_icon.dart';
import '../../models/onboarding_option.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _openModule(BuildContext context, OnboardingOption option) async {
    await MockSession.setTrainingFocus(option.title);
    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      ModuleExerciseCatalog.moduleRouteFor(option),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CinematicNavBar(backLabel: 'Back'),
            Text(
              '¿Qué quieres entrenar hoy?',
              style: AppTypography.display(24),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu elección abre un ejercicio inmersivo al instante.',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: OnboardingOption.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = OnboardingOption.values[index];
                  return _OnboardingCard(
                    option: option,
                    onTap: () => _openModule(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatefulWidget {
  const _OnboardingCard({
    required this.option,
    required this.onTap,
  });

  final OnboardingOption option;
  final VoidCallback onTap;

  @override
  State<_OnboardingCard> createState() => _OnboardingCardState();
}

class _OnboardingCardState extends State<_OnboardingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final isActive = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GlassPanel(
        accent: isActive ? option.accent : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        onTap: widget.onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModuleNeonIcon(
              type: option.iconType,
              accentStart: option.accent,
              accentEnd: option.accent,
              isActive: isActive,
              size: 38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title, style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  Text(
                    option.description,
                    style: AppTypography.caption.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isActive ? option.accent : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
