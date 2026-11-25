import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/training_context.dart';
import '../../models/eq_practice.dart';
import '../widgets/level_selector.dart';
import '../widgets/module_screen_layout.dart';
import '../widgets/training_context_dialog.dart';
import 'eq_band_exercise_screen.dart';
import 'pink_intro_screen.dart';

class EqAdvancedScreen extends StatefulWidget {
  const EqAdvancedScreen({super.key});

  @override
  State<EqAdvancedScreen> createState() => _EqAdvancedScreenState();
}

class _EqAdvancedScreenState extends State<EqAdvancedScreen> {
  /// Level chosen on each card with levels; starts at the highest that
  /// can be played.
  final Map<EqSource, int> _levels = {
    for (final source in EqSource.values)
      if (EqPractice.ladder(source) case final ladder?) source: ladder.playable,
  };

  static const _pinkIntro = 'pink';

  Future<bool?> _openPinkIntro({required bool beforePractice}) async {
    await MockSession.markIntroSeen(_pinkIntro);
    if (!mounted) return null;
    return Navigator.push<bool>(
      context,
      AppTransitions.cinematicRoute<bool>(
        settings: const RouteSettings(name: '/module/frecuencias/referencia'),
        screen: PinkIntroScreen(beforePractice: beforePractice),
      ),
    );
  }

  Future<void> _open(EqSource source) async {
    if (!await ensureCanPractice(context) || !mounted) return;
    final started = await showTrainingContext(
      context,
      TrainingContextIds.eq,
      actionLabel: 'ESCUCHAR',
      shortWhenSeen: true,
    );
    if (!started || !mounted) return;
    // First time in pink noise: the listening reference, which can be
    // skipped. It stays available from the card.
    if (source == EqSource.pink && !MockSession.hasSeenIntro(_pinkIntro)) {
      final go = await _openPinkIntro(beforePractice: true);
      if (go != true || !mounted) return;
    }
    final ladder = EqPractice.ladder(source);
    final level = _levels[source];
    final exercise = EqPractice.pick(source, level: level);
    if (exercise == null || !mounted) return;
    final before = ladder?.playable;
    await Navigator.push(
      context,
      AppTransitions.cinematicRoute<void>(
        settings: const RouteSettings(name: '/module/frecuencias/banda'),
        screen: EqBandExerciseScreen.band(
          source: source,
          exercise: exercise,
          level: level,
        ),
      ),
    );
    if (!mounted || ladder == null) return;
    // A level unlocked during the practice becomes the selected one.
    setState(() {
      final now = ladder.playable;
      if (now != before) _levels[source] = now;
    });
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
            _SourceCard(
              source: source,
              onOpen: () => _open(source),
              level: _levels[source],
              onLevel: (level) => setState(() => _levels[source] = level),
              onReference: source == EqSource.pink
                  ? () => _openPinkIntro(beforePractice: false)
                  : null,
            ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.onOpen,
    required this.onLevel,
    this.level,
    this.onReference,
  });

  final EqSource source;
  final VoidCallback onOpen;
  final int? level;
  final ValueChanged<int> onLevel;

  /// Opens the listening reference (pink noise).
  final VoidCallback? onReference;

  @override
  Widget build(BuildContext context) {
    final level = this.level;
    final ladder = EqPractice.ladder(source);
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
          if (level != null && ladder != null) ...[
            const SizedBox(height: 10),
            LevelSelector(
              ladder: ladder,
              selected: level,
              detail: EqPractice.levelDetail(source, level),
              onSelect: onLevel,
            ),
          ],
          if (onReference != null)
            TextButton.icon(
              onPressed: onReference,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                foregroundColor: AppColors.cyan,
              ),
              icon: const Icon(Icons.headphones_rounded, size: 16),
              label: const Text('Escuchar la referencia'),
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
