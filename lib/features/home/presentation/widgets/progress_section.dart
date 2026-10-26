import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/section_header.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key, this.locked = false, this.onLoginTap});

  final bool locked;
  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tu progreso',
          subtitle: locked
              ? 'Tu entrenamiento apenas comienza.'
              : 'Motivación sutil, evolución real',
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Racha',
                      value: '${MockSession.streakDays}d',
                      color: AppColors.orange,
                      muted: locked,
                    ),
                  ),
                  _divider,
                  Expanded(
                    child: _StatTile(
                      icon: Icons.bolt_rounded,
                      label: 'XP',
                      value: '${MockSession.xp}',
                      color: AppColors.cyan,
                      muted: locked,
                    ),
                  ),
                  _divider,
                  Expanded(
                    child: _StatTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Logros',
                      value: '${MockSession.achievements}',
                      color: AppColors.amber,
                      muted: locked,
                    ),
                  ),
                  _divider,
                  Expanded(
                    child: _StatTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Constancia',
                      value: '${MockSession.trainingConsistency}%',
                      color: AppColors.blue,
                      muted: locked,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Positioned.fill(
                child: GestureDetector(
                  onTap: onLoginTap ?? () => AppNavigator.openLogin(context),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withValues(alpha: 0.22),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: AppColors.purpleLight.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Guarda tu evolución auditiva',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Widget get _divider => Container(
        width: 1,
        height: 36,
        color: AppColors.glassBorder,
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: muted ? 0.45 : 0.85)),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.cardTitle.copyWith(
            fontSize: 15,
            color: muted ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
