import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';

class LoginPromptBanner extends StatelessWidget {
  const LoginPromptBanner({
    super.key,
    required this.onDismiss,
    required this.onSignedIn,
  });

  final VoidCallback onDismiss;
  final VoidCallback onSignedIn;

  static const _message = 'Guarda tu progreso.';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GlassPanel(
        accent: AppColors.purple,
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple.withValues(alpha: 0.18),
                    border: Border.all(color: AppColors.purpleLight.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    size: 18,
                    color: AppColors.purpleLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_message, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'Continúa entrenando y desbloquea tu evolución auditiva.',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'INICIAR SESIÓN',
              compact: true,
              onPressed: () async {
                await AppNavigator.openLogin(context);
                if (MockSession.hasFullAccess) onSignedIn();
              },
            ),
          ],
        ),
      ),
    );
  }
}
