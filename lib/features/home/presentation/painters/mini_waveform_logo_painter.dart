import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MiniWaveformLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.purpleLight, AppColors.blue],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const h = [0.35, 0.8, 0.55, 1.0, 0.45];
    for (var i = 0; i < h.length; i++) {
      final x = i * (size.width / (h.length - 1));
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * (1 - h[i])),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
