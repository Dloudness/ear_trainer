import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Play/pause button with a thin progress line, for reference clips.
class ListenChip extends StatelessWidget {
  const ListenChip({
    super.key,
    required this.label,
    required this.playing,
    required this.progress,
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final bool playing;
  final double progress;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final color = playing ? AppColors.cyan : AppColors.textSecondary;
    return Semantics(
      button: true,
      label: playing ? 'Pausar $label' : 'Escuchar $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: wide ? double.infinity : null,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            color: playing ? AppColors.cyan.withValues(alpha: 0.10) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
