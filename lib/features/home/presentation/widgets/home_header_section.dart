import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/home_top_bar.dart';
import '../../models/app_language.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    this.onProfileTap,
    this.profileLocked = false,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback? onProfileTap;
  final bool profileLocked;

  @override
  Widget build(BuildContext context) {
    final greeting = MockSession.isGuest
        ? 'Tu oído sigue entrenando.'
        : MockSession.hasFullAccess
            ? 'Bienvenido de nuevo, ${MockSession.displayName}.'
            : MockSession.isLightMode
                ? 'Tu oído está despierto. Sigue explorando.'
                : 'Bienvenido a Ear Trainer.';

    return Column(
      children: [
        HomeTopBar(
          language: language,
          onLanguageChanged: onLanguageChanged,
          onProfileTap: onProfileTap,
          profileLocked: profileLocked,
        ),
        const SizedBox(height: 12),
        Text(
          greeting,
          textAlign: TextAlign.center,
          style: AppTypography.tagline(17).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (MockSession.trainingFocus != null) ...[
          const SizedBox(height: 8),
          Text(
            'Enfoque: ${MockSession.trainingFocus}',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}
