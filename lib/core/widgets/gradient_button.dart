import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.compact = false,
    this.icon,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;
  final IconData? icon;

  /// Listen-style pulse and tap feedback for ESCUCHAR interactions.
  final bool emphasized;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  AnimationController? _pulseController;
  Animation<double>? _pulseGlow;

  @override
  void initState() {
    super.initState();
    _syncPulseController();
  }

  void _syncPulseController() {
    if (widget.emphasized && _pulseController == null) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3400),
      )..repeat(reverse: true);
      _pulseGlow = Tween<double>(begin: 0.22, end: 0.38).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    } else if (!widget.emphasized && _pulseController != null) {
      _pulseController!.dispose();
      _pulseController = null;
      _pulseGlow = null;
    }
  }

  @override
  void didUpdateWidget(covariant GradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emphasized != widget.emphasized) {
      _syncPulseController();
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 44.0 : 50.0;
    final enabled = widget.onPressed != null;
    final baseShadow = _hovered ? 0.38 : 0.25;

    Widget button = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 20 : 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              colors: _hovered || _pressed
                  ? [AppColors.purpleDeep, AppColors.blueDeep]
                  : [
                      AppColors.purpleDeep.withValues(alpha: 0.92),
                      AppColors.blueDeep.withValues(alpha: 0.92),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: baseShadow),
                blurRadius: _hovered ? 22 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: widget.compact ? 1.6 : 2,
                  color: Colors.white,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.emphasized && _pulseGlow != null) {
      button = AnimatedBuilder(
        animation: _pulseGlow!,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: _pulseGlow!.value * 0.55),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: button,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: button,
      ),
    );
  }
}
