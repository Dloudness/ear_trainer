import 'package:flutter/material.dart';

enum OptionSlot { a, b, c, d }

/// Muted cinematic palettes for multiple-choice options.
class OptionChoiceColors {
  const OptionChoiceColors({
    required this.accent,
    required this.glow,
    required this.tint,
    required this.label,
  });

  final Color accent;
  final Color glow;
  final Color tint;
  final String label;

  static const a = OptionChoiceColors(
    accent: Color(0xFF6B9FD4),
    glow: Color(0xFF3B82F6),
    tint: Color(0xFF141E32),
    label: 'A',
  );

  static const b = OptionChoiceColors(
    accent: Color(0xFFD4A574),
    glow: Color(0xFFE89550),
    tint: Color(0xFF221910),
    label: 'B',
  );

  static const c = OptionChoiceColors(
    accent: Color(0xFF9B87D4),
    glow: Color(0xFF9333EA),
    tint: Color(0xFF1A1528),
    label: 'C',
  );

  static const d = OptionChoiceColors(
    accent: Color(0xFF6BC5D4),
    glow: Color(0xFF22D3EE),
    tint: Color(0xFF101E22),
    label: 'D',
  );

  static OptionChoiceColors forSlot(OptionSlot slot) => switch (slot) {
        OptionSlot.a => a,
        OptionSlot.b => b,
        OptionSlot.c => c,
        OptionSlot.d => d,
      };
}

abstract final class OptionChoicePalette {
  static double borderAlpha({required bool selected, required bool hovered}) {
    if (selected) return 0.52;
    if (hovered) return 0.38;
    return 0.26;
  }

  static double glowAlpha({required bool selected, required bool hovered}) {
    if (selected) return 0.22;
    if (hovered) return 0.14;
    return 0.07;
  }

  static double tintAlpha({required bool selected, required bool hovered}) {
    if (selected) return 0.72;
    if (hovered) return 0.58;
    return 0.42;
  }
}
