import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/option_choice_palette.dart';

/// Answer card in the Orb style: a glass panel with a gradient letter badge.
/// Hover lights the border in the slot color; the chosen answer glows.
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

  /// Full-width row (lists of answers). Otherwise a centered tile for
  /// side-by-side A/B answers.
  final bool compact;

  /// Kept for callers of the previous design; no longer drawn.
  final Animation<double>? pulse;
  final bool showWaveform;

  @override
  State<OptionChoiceCard> createState() => _OptionChoiceCardState();
}

class _OptionChoiceCardState extends State<OptionChoiceCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = OptionChoiceColors.forSlot(widget.slot);
    final selected = widget.selected;
    final lit = selected || _hovered;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 60),
              padding: widget.compact
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: selected ? null : Colors.white.withValues(alpha: 0.04),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.glow.withValues(alpha: 0.24),
                          colors.glow.withValues(alpha: 0.06),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: selected
                      ? colors.accent.withValues(alpha: 0.9)
                      : _hovered
                      ? colors.accent.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  if (lit)
                    BoxShadow(
                      color: colors.glow.withValues(
                        alpha: selected ? 0.30 : 0.14,
                      ),
                      blurRadius: selected ? 30 : 20,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: widget.compact
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  _LetterBadge(colors: colors, lit: lit),
                  const SizedBox(width: 12),
                  Flexible(
                    fit: widget.compact ? FlexFit.tight : FlexFit.loose,
                    child: Text(
                      widget.label,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: lit
                            ? AppColors.textPrimary
                            : AppColors.textPrimary.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  if (selected && widget.compact) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colors.accent,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.colors, required this.lit});

  final OptionChoiceColors colors;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: lit ? LinearGradient(colors: colors.gradient) : null,
        color: lit ? null : colors.glow.withValues(alpha: 0.16),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: colors.glow.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        colors.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: lit ? Colors.white : colors.accent,
        ),
      ),
    );
  }
}
