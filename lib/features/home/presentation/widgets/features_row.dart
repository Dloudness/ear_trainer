import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/feature_item.dart';

class FeaturesRow extends StatelessWidget {
  const FeaturesRow({
    super.key,
    required this.features,
    required this.isWide,
  });

  final List<FeatureItem> features;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final f in features) FeatureChip(feature: f)],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 12,
      children: [for (final f in features) FeatureChip(feature: f)],
    );
  }
}

class FeatureChip extends StatelessWidget {
  const FeatureChip({super.key, required this.feature});

  final FeatureItem feature;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(feature.icon, size: 14, color: feature.color.withValues(alpha: 0.85)),
        const SizedBox(width: 5),
        Text(
          feature.label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w300,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
