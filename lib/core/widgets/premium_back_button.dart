import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../theme/app_colors.dart';

/// Minimal glass back control — premium, non-Material default styling.
class PremiumBackButton extends StatefulWidget {
  const PremiumBackButton({
    super.key,
    this.label = 'Back',
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<PremiumBackButton> createState() => _PremiumBackButtonState();
}

class _PremiumBackButtonState extends State<PremiumBackButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: _hovered ? AppColors.glassBorderHover : AppColors.glassBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 12,
                  color: _hovered ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: _hovered ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal glass home control — appears only after entering the app hub.
class PremiumHomeButton extends StatefulWidget {
  const PremiumHomeButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<PremiumHomeButton> createState() => _PremiumHomeButtonState();
}

class _PremiumHomeButtonState extends State<PremiumHomeButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }
    AppNavigator.goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _hovered
                  ? AppColors.purple.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: _hovered
                    ? AppColors.purpleLight.withValues(alpha: 0.35)
                    : AppColors.glassBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_rounded,
                  size: 13,
                  color: _hovered ? AppColors.purpleLight : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: _hovered ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top navigation row with optional back and home controls.
class CinematicNavBar extends StatelessWidget {
  const CinematicNavBar({
    super.key,
    this.showBack = true,
    this.backLabel = 'Back',
    this.onBack,
    this.showHome = false,
    this.onHome,
  });

  final bool showBack;
  final String backLabel;
  final VoidCallback? onBack;
  final bool showHome;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    if (!showBack && !showHome) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (showBack)
            PremiumBackButton(label: backLabel, onPressed: onBack)
          else
            const SizedBox(width: 1),
          const Spacer(),
          if (showHome) PremiumHomeButton(onPressed: onHome),
        ],
      ),
    );
  }
}
