import 'package:flutter/material.dart';

import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/training_context.dart';
import '../../models/musical_pool.dart';

Future<bool> showTrainingContext(
  BuildContext context,
  MusicalPool pool, {
  bool required = false,
}) async {
  TrainingContextCopy copy;
  try {
    copy = await TrainingContextLibrary.forId(pool.name);
  } catch (error) {
    debugPrint('TrainingContext: $error');
    return true;
  }
  if (!context.mounted) return false;

  final started = await showDialog<bool>(
    context: context,
    barrierDismissible: !required,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) => TrainingContextDialog(
      copy: copy,
      full: MockSession.usesFullTrainingContext,
    ),
  );
  if (started == true) {
    await MockSession.markTrainingContextSeen(pool.name);
  }
  return started == true;
}

class TrainingContextLink extends StatelessWidget {
  const TrainingContextLink({super.key, required this.pool});

  final MusicalPool pool;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showTrainingContext(context, pool),
        icon: const Icon(Icons.info_outline_rounded, size: 15),
        label: const Text('¿Por qué entrenar esto?'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyan,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ),
    );
  }
}

class TrainingContextDialog extends StatelessWidget {
  const TrainingContextDialog({
    super.key,
    required this.copy,
    required this.full,
  });

  final TrainingContextCopy copy;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final variant = full ? copy.full : copy.short;
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: const Color(0xFF10141C),
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 480 ? 16 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(copy.title, style: AppTypography.display(22)),
              const SizedBox(height: 12),
              Text(
                variant.intro,
                style: AppTypography.tagline(15).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (variant.skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final skill in variant.skills) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          skill,
                          style: AppTypography.tagline(14).copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              if (variant.closing.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  variant.closing,
                  style: AppTypography.tagline(14).copyWith(
                    color: AppColors.blue,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'EMPEZAR',
                  compact: true,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
