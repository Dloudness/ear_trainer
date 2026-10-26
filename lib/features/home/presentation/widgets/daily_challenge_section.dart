import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/home_mock_data.dart';

class DailyChallengeSection extends StatelessWidget {
  const DailyChallengeSection({
    super.key,
    this.onChallengeReturn,
    this.onLoginRequired,
  });

  final VoidCallback? onChallengeReturn;
  final VoidCallback? onLoginRequired;

  Future<void> _handleTap(BuildContext context) async {
    if (!MockSession.canAttemptDailyChallenge) {
      onLoginRequired?.call();
      await AppNavigator.openLogin(context);
      onChallengeReturn?.call();
      return;
    }

    await Navigator.pushNamed(context, AppRoutes.dailyChallenge);
    onChallengeReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = MockSession.isLightMode;
    final freeUsed = MockSession.hasUsedFreeDailyChallenge;
    final subtitle = isLight && !freeUsed
        ? 'Tu desafío gratuito de hoy'
        : isLight && freeUsed
            ? 'Inicia sesión para continuar entrenando'
            : 'Un minuto para afinar tu oído';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Desafío diario',
          subtitle: subtitle,
        ),
        const SizedBox(height: 16),
        GlassPanel(
          accent: AppColors.purple,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt_outlined,
                    size: 18,
                    color: AppColors.purpleLight.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hoy',
                    style: AppTypography.caption.copyWith(color: AppColors.purpleLight),
                  ),
                  if (isLight && !freeUsed) ...[
                    const Spacer(),
                    Text(
                      'Gratis',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cyan,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                HomeMockData.dailyChallengeQuestion,
                style: AppTypography.tagline(17),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: isLight && freeUsed ? 'DESBLOQUEAR' : 'ESCUCHAR',
                compact: true,
                icon: Icons.play_arrow_rounded,
                emphasized: !(isLight && freeUsed),
                onPressed: () => _handleTap(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
