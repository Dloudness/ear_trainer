import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StartTrainingButton extends StatefulWidget {
  const StartTrainingButton({super.key, required this.pulseAnimation});

  final Animation<double> pulseAnimation;

  @override
  State<StartTrainingButton> createState() => _StartTrainingButtonState();
}

class _StartTrainingButtonState extends State<StartTrainingButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedBuilder(
          animation: widget.pulseAnimation,
          builder: (context, child) {
            final pulse = widget.pulseAnimation.value;
            final glowAlpha = _hovered ? 0.45 : 0.22 + pulse * 0.12;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: _hovered
                      ? [AppColors.purpleDeep, AppColors.blueDeep]
                      : [
                          Color.lerp(AppColors.purpleDeep, AppColors.purple, pulse * 0.15)!,
                          Color.lerp(AppColors.blueDeep, AppColors.blue, pulse * 0.15)!,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: glowAlpha),
                    blurRadius: 20 + pulse * 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COMENZAR ENTRENAMIENTO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: _hovered ? 1 : 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
