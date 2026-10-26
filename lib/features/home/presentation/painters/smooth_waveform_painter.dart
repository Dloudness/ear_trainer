import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SmoothWaveformPainter extends CustomPainter {
  SmoothWaveformPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final path = Path();
    const steps = 60;

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final envelope = math.sin(t * math.pi);
      final wave = math.sin(t * math.pi * 5 + phase * math.pi * 2);
      final y = midY + wave * envelope * (size.height * 0.38);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cyan.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.purpleLight, AppColors.cyan, AppColors.blue],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(SmoothWaveformPainter old) => old.phase != phase;
}
