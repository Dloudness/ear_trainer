import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../data/home_mock_data.dart';

class RecommendedListenSection extends StatelessWidget {
  const RecommendedListenSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Escucha recomendada',
          subtitle: 'Una referencia para afinar tu percepción',
        ),
        const SizedBox(height: 16),
        GlassPanel(
          accent: AppColors.purple,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.headphones_outlined,
                    size: 20,
                    color: AppColors.purple.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HomeMockData.recommendedListenTitle,
                          style: AppTypography.cardTitle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          HomeMockData.recommendedListenDetail,
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'ESCUCHAR',
                compact: true,
                icon: Icons.play_arrow_rounded,
                emphasized: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
