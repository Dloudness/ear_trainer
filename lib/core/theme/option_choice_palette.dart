import 'package:flutter/material.dart';

enum OptionSlot { a, b, c, d }

/// Vivid per-slot colors for answers, matching the Orb player
/// (cyan, purple, blue, pink).
class OptionChoiceColors {
  const OptionChoiceColors({
    required this.accent,
    required this.glow,
    required this.tint,
    required this.label,
    required this.gradient,
  });

  /// Readable color for the letter, icons and borders.
  final Color accent;
  final Color glow;
  final Color tint;
  final String label;

  /// Fill of the letter badge.
  final List<Color> gradient;

  static const a = OptionChoiceColors(
    accent: Color(0xFF67E8F9),
    glow: Color(0xFF22D3EE),
    tint: Color(0xFF0E2A33),
    label: 'A',
    gradient: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
  );

  static const b = OptionChoiceColors(
    accent: Color(0xFFD8B4FE),
    glow: Color(0xFFA855F7),
    tint: Color(0xFF241536),
    label: 'B',
    gradient: [Color(0xFFA855F7), Color(0xFF6366F1)],
  );

  static const c = OptionChoiceColors(
    accent: Color(0xFF93C5FD),
    glow: Color(0xFF3B82F6),
    tint: Color(0xFF111D38),
    label: 'C',
    gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  static const d = OptionChoiceColors(
    accent: Color(0xFFF9A8D4),
    glow: Color(0xFFEC4899),
    tint: Color(0xFF2E1224),
    label: 'D',
    gradient: [Color(0xFFEC4899), Color(0xFFA855F7)],
  );

  static OptionChoiceColors forSlot(OptionSlot slot) => switch (slot) {
        OptionSlot.a => a,
        OptionSlot.b => b,
        OptionSlot.c => c,
        OptionSlot.d => d,
      };
}
