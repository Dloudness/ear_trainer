import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/practice_levels.dart';

/// Level chips for a [LevelLadder]: unlocked levels can be chosen, locked
/// ones show a lock. Below, what the selected level is and how to open the
/// next one.
class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.ladder,
    required this.selected,
    required this.onSelect,
    this.detail,
  });

  final LevelLadder ladder;
  final int selected;
  final ValueChanged<int> onSelect;

  /// What the selected level means (e.g. how many reference listens).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final unlocked = ladder.unlocked;
    final hint = ladder.unlockHint(selected);
    final caption = [?detail, ?hint].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var level = 1; level <= ladder.maxLevel; level++) ...[
              if (level > 1) const SizedBox(width: 8),
              Expanded(
                child: () {
                  final premium =
                      LevelLadder.isPremium(level) && !MockSession.hasPremium;
                  final earned = level <= unlocked;
                  return _LevelChip(
                    label: ladder.name(level),
                    selected: level == selected,
                    locked: premium || !earned,
                    premium: premium,
                    // A Premium level opens the plans; a level not yet
                    // earned does nothing.
                    onTap: premium
                        ? () => Navigator.pushNamed(context, AppRoutes.plans)
                        : earned
                        ? () => onSelect(level)
                        : null,
                  );
                }(),
              ),
            ],
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.locked,
    this.premium = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;

  /// Locked because it needs Premium (discreet amber lock).
  final bool premium;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = premium
        ? AppColors.amber.withValues(alpha: 0.85)
        : locked
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : selected
        ? AppColors.cyan
        : AppColors.textSecondary;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: premium
          ? '$label, Premium'
          : locked
          ? '$label, bloqueado'
          : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.cyan : color.withValues(alpha: 0.35),
            ),
            color: selected ? AppColors.cyan.withValues(alpha: 0.12) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked) ...[
                Icon(Icons.lock_rounded, size: 13, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
