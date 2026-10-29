import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../demo/models/demo_experience_args.dart';
import '../../models/module_exercise_catalog.dart';

class ModuleExerciseListCard extends StatefulWidget {
  const ModuleExerciseListCard({
    super.key,
    required this.entry,
    required this.accent,
  });

  final ModuleExerciseEntry entry;
  final Color accent;

  @override
  State<ModuleExerciseListCard> createState() => _ModuleExerciseListCardState();
}

class _ModuleExerciseListCardState extends State<ModuleExerciseListCard> {
  bool get _locked {
    final access = widget.entry.access;
    return access != null && !MockSession.allowsAccess(access);
  }

  String get _lockLabel {
    return widget.entry.access == 'premium' ? 'Con premium' : 'Con una cuenta';
  }

  Future<void> _onPressed() async {
    if (_locked) {
      final opened = widget.entry.access == 'premium'
          ? await promptPremiumCode(context)
          : await promptRegister(context);
      if (opened && mounted) setState(() {});
      return;
    }
    await Navigator.pushNamed(
      context,
      AppRoutes.demo,
      arguments: DemoExperienceArgs(
        category: widget.entry.category,
        exerciseIndex: widget.entry.exerciseIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final locked = _locked;

    return GlassPanel(
      accent: widget.accent,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: widget.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.title,
            style: AppTypography.cardTitle.copyWith(fontSize: 14, height: 1.25),
          ),
          if (locked) ...[
            const SizedBox(height: 6),
            Text(
              _lockLabel,
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          GradientButton(
            label: locked ? 'BLOQUEADO' : 'ESCUCHAR',
            compact: true,
            dense: true,
            icon: locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
            emphasized: !locked,
            onPressed: () => _onPressed(),
          ),
        ],
      ),
    );
  }
}
