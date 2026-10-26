import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/option_choice_palette.dart';

/// Premium multiple-choice card with distinct cinematic color per slot.
class OptionChoiceCard extends StatefulWidget {
  const OptionChoiceCard({
    super.key,
    required this.slot,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.pulse,
    this.showWaveform = false,
  });

  final OptionSlot slot;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final Animation<double>? pulse;
  final bool showWaveform;

  @override
  State<OptionChoiceCard> createState() => _OptionChoiceCardState();
}

class _OptionChoiceCardState extends State<OptionChoiceCard> {
  bool _hovered = false;
  bool _pressed = false;

  OptionChoiceColors get _colors => OptionChoiceColors.forSlot(widget.slot);

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final active = widget.selected || _hovered;
    final borderAlpha = OptionChoicePalette.borderAlpha(
      selected: widget.selected,
      hovered: _hovered,
    );
    final glowAlpha = OptionChoicePalette.glowAlpha(
      selected: widget.selected,
      hovered: _hovered,
    );
    final tintAlpha = OptionChoicePalette.tintAlpha(
      selected: widget.selected,
      hovered: _hovered,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.selected ? 1.025 : _pressed ? 0.982 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: widget.compact
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 14)
                : const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Color.alphaBlend(
                colors.tint.withValues(alpha: tintAlpha),
                Colors.white.withValues(alpha: 0.03),
              ),
              border: Border.all(
                color: colors.accent.withValues(alpha: borderAlpha),
                width: widget.selected ? 1.0 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: colors.glow.withValues(alpha: glowAlpha),
                  blurRadius: widget.selected ? 24 : 18,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: widget.compact ? _buildCompact(colors, active) : _buildStandard(colors, active),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(OptionChoiceColors colors, bool active) {
    return Row(
      children: [
        _OptionBadge(colors: colors, active: active),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.label,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 14,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        if (widget.selected)
          Icon(Icons.check_circle_rounded, size: 16, color: colors.accent),
      ],
    );
  }

  Widget _buildStandard(OptionChoiceColors colors, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showWaveform) ...[
          _buildWaveform(colors, active),
          const SizedBox(height: 14),
        ] else
          _OptionBadge(colors: colors, active: active),
        if (!widget.showWaveform) const SizedBox(height: 12),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: AppTypography.cardTitle.copyWith(
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(OptionChoiceColors colors, bool active) {
    final bars = _OptionWaveformBars(active: widget.selected, color: colors.accent);
    if (widget.pulse != null && widget.selected) {
      return ScaleTransition(scale: widget.pulse!, child: bars);
    }
    return bars;
  }
}

class _OptionBadge extends StatelessWidget {
  const _OptionBadge({required this.colors, required this.active});

  final OptionChoiceColors colors;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.tint.withValues(alpha: active ? 0.85 : 0.55),
        border: Border.all(color: colors.accent.withValues(alpha: active ? 0.55 : 0.32)),
      ),
      alignment: Alignment.center,
      child: Text(
        colors.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: colors.accent.withValues(alpha: active ? 1 : 0.75),
        ),
      ),
    );
  }
}

class _OptionWaveformBars extends StatelessWidget {
  const _OptionWaveformBars({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: CustomPaint(
        painter: _OptionWaveformPainter(color: color, active: active),
      ),
    );
  }
}

class _OptionWaveformPainter extends CustomPainter {
  _OptionWaveformPainter({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: active ? 0.9 : 0.5)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    const heights = [0.35, 0.72, 0.48, 0.95, 0.58, 0.82, 0.42];
    for (var i = 0; i < heights.length; i++) {
      final x = i * (size.width / (heights.length - 1));
      final h = heights[i] * (active ? 1.0 : 0.62);
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * (1 - h)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OptionWaveformPainter oldDelegate) {
    return oldDelegate.active != active || oldDelegate.color != color;
  }
}

/// Listen-phase comparison card — shares option slot color identity.
class OptionListenCard extends StatefulWidget {
  const OptionListenCard({
    super.key,
    required this.slot,
    required this.label,
    required this.isPlaying,
    required this.onTap,
    this.isPaused = false,
    this.pulse,
  });

  final OptionSlot slot;
  final String label;
  final bool isPlaying;
  final bool isPaused;
  final VoidCallback onTap;
  final Animation<double>? pulse;

  @override
  State<OptionListenCard> createState() => _OptionListenCardState();
}

class _OptionListenCardState extends State<OptionListenCard> {
  bool _hovered = false;
  bool _pressed = false;

  OptionChoiceColors get _colors => OptionChoiceColors.forSlot(widget.slot);

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final active = widget.isPlaying || widget.isPaused || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Color.alphaBlend(
                colors.tint.withValues(alpha: active ? 0.65 : 0.42),
                Colors.white.withValues(alpha: 0.03),
              ),
              border: Border.all(
                color: colors.accent.withValues(alpha: active ? 0.45 : 0.26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: colors.glow.withValues(alpha: widget.isPlaying ? 0.2 : 0.08),
                  blurRadius: widget.isPlaying ? 22 : 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.pulse != null && widget.isPlaying)
                  ScaleTransition(
                    scale: widget.pulse!,
                    child: _OptionWaveformBars(active: true, color: colors.accent),
                  )
                else
                  _OptionWaveformBars(active: widget.isPlaying, color: colors.accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _OptionBadge(colors: colors, active: active),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.label,
                              style: AppTypography.cardTitle.copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isPlaying
                            ? 'Reproduciendo… · Toca para pausar'
                            : widget.isPaused
                                ? 'Pausado · Toca para reanudar'
                                : 'Toca para escuchar',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  widget.isPlaying
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: colors.accent,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
