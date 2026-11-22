import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/orb_logo.dart';

/// Emotional entry point — NOT the training home.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final logo = math.min(
            260.0,
            math.min(constraints.maxWidth * 0.66, constraints.maxHeight * 0.32),
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
                child: Column(
                  children: [
                    const _Wordmark(),
                    const Spacer(),
                    OrbLogo(size: logo),
                    const SizedBox(height: 44),
                    Text(
                      'Afina tu oído.',
                      textAlign: TextAlign.center,
                      style: AppTypography.display(34).copyWith(
                        height: 1.1,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Frecuencias, dinámica e intervalos. Ejercicios cortos '
                        'que entrenan cómo escuchas.',
                        textAlign: TextAlign.center,
                        style: AppTypography.tagline(15).copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _PrimaryButton(
                      label: 'Comenzar a entrenar',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.onboarding),
                    ),
                    const SizedBox(height: 12),
                    _SecondaryButton(
                      label: 'Ya tengo cuenta',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan,
            boxShadow: [
              BoxShadow(color: AppColors.cyan.withValues(alpha: 0.8), blurRadius: 12),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'EAR TRAINER',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 6,
            color: AppColors.textPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 58,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(29),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.cyan, AppColors.blue, AppColors.purpleDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: _hovered ? 0.5 : 0.35),
                    blurRadius: _hovered ? 48 : 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white.withValues(alpha: _hovered ? 0.08 : 0.04),
              border: Border.all(
                color: Colors.white.withValues(alpha: _hovered ? 0.24 : 0.14),
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
