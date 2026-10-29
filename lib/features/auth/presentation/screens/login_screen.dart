import 'package:flutter/material.dart';

import '../../../../core/auth/account_auth.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _enterHome(BuildContext context, {required bool guest}) async {
    if (guest) {
      await AccountAuth.continueAsGuest();
    } else {
      await AccountAuth.registerWithMock();
    }
    if (!context.mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    AppNavigator.goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CinematicNavBar(backLabel: 'Back'),
            const Spacer(),
            Text('Accede', style: AppTypography.display(26)),
            const SizedBox(height: 8),
            Text(
              'Continúa tu entrenamiento auditivo.',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 36),
            _LoginOption(
              icon: Icons.g_mobiledata_rounded,
              label: 'Continue with Google',
              onTap: () => _enterHome(context, guest: false),
            ),
            const SizedBox(height: 10),
            _LoginOption(
              icon: Icons.apple_rounded,
              label: 'Continue with Apple',
              onTap: () => _enterHome(context, guest: false),
            ),
            const SizedBox(height: 10),
            _LoginOption(
              icon: Icons.mail_outline_rounded,
              label: 'Continue with Email',
              onTap: () => _enterHome(context, guest: false),
            ),
            const SizedBox(height: 24),
            _LoginOption(
              icon: Icons.person_outline_rounded,
              label: 'Guest Mode',
              onTap: () => _enterHome(context, guest: true),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'ENTRAR',
                compact: true,
                onPressed: () => _enterHome(context, guest: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginOption extends StatelessWidget {
  const _LoginOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
