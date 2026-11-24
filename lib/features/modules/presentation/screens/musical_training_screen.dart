import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/session/mock_session.dart';
import '../../models/musical_pool.dart';
import '../../models/musical_sections.dart';
import '../widgets/level_selector.dart';
import '../widgets/module_screen_layout.dart';
import '../widgets/training_context_dialog.dart';
import 'musical_exercise_screen.dart';

class MusicalTrainingScreen extends StatefulWidget {
  const MusicalTrainingScreen({super.key});

  @override
  State<MusicalTrainingScreen> createState() => _MusicalTrainingScreenState();
}

class _MusicalTrainingScreenState extends State<MusicalTrainingScreen> {
  Future<void> _open(MusicalPool pool) async {
    if (MusicalPools.isCardLocked(pool)) {
      final unlocked = pool == MusicalPool.chords
          ? await promptPremiumCode(context)
          : await promptRegister(context);
      if (!mounted) return;
      if (unlocked) setState(() {});
      if (!unlocked || MusicalPools.isCardLocked(pool)) return;
    }

    if (MusicalPools.needsAccountPrompt(pool)) {
      final registered = await promptRegister(context);
      if (!mounted) return;
      if (registered) setState(() {});
      if (!registered) return;
    }

    if (!await ensureCanPractice(context) || !mounted) return;

    if (!MockSession.hasSeenTrainingContext(MusicalPools.contextId(pool))) {
      final started = await showTrainingContext(
        context,
        MusicalPools.contextId(pool),
        required: true,
      );
      if (!mounted || !started) return;
    }

    final ladder = MusicalPools.ladder(pool);
    final level = ladder == null ? null : (_levels[pool] ?? ladder.unlocked);
    final exercise = MusicalPools.pick(pool, level: level);
    if (exercise == null || !mounted) return;
    final before = ladder?.unlocked;
    await Navigator.push(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/musical/exercise'),
        screen: MusicalExerciseScreen(
          pool: pool,
          exercise: exercise,
          level: level,
        ),
      ),
    );
    if (!mounted) return;
    // A level unlocked during the practice becomes the selected one.
    setState(() {
      if (ladder != null && ladder.unlocked != before) {
        _levels[pool] = ladder.unlocked;
      }
    });
  }

  /// Level chosen per pool with levels; defaults to the highest unlocked.
  final Map<MusicalPool, int> _levels = {};

  @override
  Widget build(BuildContext context) {
    return ModuleScreenLayout(
      title: 'Entrenamiento Musical',
      subtitle: 'Intervalos, acordes y percepción armónica.',
      children: [
        for (final pool in MusicalPool.values)
          _PoolCard(
            pool: pool,
            onOpen: () => _open(pool),
            level: switch (MusicalPools.ladder(pool)) {
              final ladder? => _levels[pool] ?? ladder.unlocked,
              null => null,
            },
            onLevel: (level) => setState(() => _levels[pool] = level),
          ),
      ],
    );
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({
    required this.pool,
    required this.onOpen,
    required this.onLevel,
    this.level,
  });

  final MusicalPool pool;
  final VoidCallback onOpen;
  final int? level;
  final ValueChanged<int> onLevel;

  @override
  Widget build(BuildContext context) {
    final locked = MusicalPools.isCardLocked(pool);

    return GlassPanel(
      accent: MusicalSections.accent,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  MusicalPools.title(pool),
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ),
              if (locked)
                const Icon(
                  Icons.lock_rounded,
                  color: AppColors.purple,
                  size: 18,
                ),
            ],
          ),
          if (locked) ...[
            const SizedBox(height: 6),
            Text(
              MusicalPools.lockMessage(pool),
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          TrainingContextLink(contextId: MusicalPools.contextId(pool)),
          if (!locked && level != null)
            if (MusicalPools.ladder(pool) case final ladder?) ...[
              const SizedBox(height: 10),
              LevelSelector(
                ladder: ladder,
                selected: level!,
                detail: MusicalPools.levelDetail(level!),
                onSelect: onLevel,
              ),
            ],
          const SizedBox(height: 10),
          GradientButton(
            label: locked ? 'BLOQUEADO' : 'ESCUCHAR',
            compact: true,
            dense: true,
            icon: locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
            emphasized: !locked,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
