import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle display(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w200,
        letterSpacing: size * 0.22,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle tagline(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.4,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static const caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  /// Primary exercise question — largest visual anchor.
  static TextStyle exerciseQuestion([double size = 26]) => display(size);

  /// Quiet atmospheric instruction, e.g. “Escucha atentamente.”
  static const exerciseInstruction = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.9,
    color: AppColors.textMuted,
    height: 1.45,
  );

  /// Optional supporting guidance beneath the question.
  static const exerciseHint = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.35,
    color: AppColors.textMuted,
    height: 1.5,
    fontStyle: FontStyle.italic,
  );
}
