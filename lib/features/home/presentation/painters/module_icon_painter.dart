import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/module_icon_type.dart';

class ModuleIconPainter extends CustomPainter {
  ModuleIconPainter({
    required this.type,
    required this.accentStart,
    required this.accentEnd,
    required this.glow,
  });

  final ModuleIconType type;
  final Color accentStart;
  final Color accentEnd;
  final bool glow;

  static const _pad = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(_pad, _pad, size.width - _pad * 2, size.height - _pad * 2);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accentStart, accentEnd],
    ).createShader(rect);

    Paint stroke([double width = 1.15]) => Paint()
      ..shader = shader
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Subtle always-on neon halo
    final halo = stroke(1.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow ? 3.5 : 2.0)
      ..color = accentStart.withValues(alpha: glow ? 0.35 : 0.18)
      ..shader = null;
    _drawIcon(canvas, rect, halo);

    if (glow) {
      _drawIcon(canvas, rect, stroke(1.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
    _drawIcon(canvas, rect, stroke());
  }

  void _drawIcon(Canvas canvas, Rect r, Paint paint) {
    switch (type) {
      case ModuleIconType.waveform:
        _drawWaveform(canvas, r, paint);
      case ModuleIconType.piano:
        _drawChords(canvas, r, paint);
      case ModuleIconType.eqGraph:
        _drawEqGraph(canvas, r, paint);
      case ModuleIconType.gauge:
        _drawDynamics(canvas, r, paint);
      case ModuleIconType.headphones:
        _drawHeadphones(canvas, r, paint);
      case ModuleIconType.frequency:
        _drawFrequency(canvas, r, paint);
      case ModuleIconType.live:
        _drawLive(canvas, r, paint);
    }
  }

  /// Sharp jagged waveform — reference Intervalos icon.
  void _drawWaveform(Canvas canvas, Rect r, Paint paint) {
    const pts = [0.45, 0.95, 0.35, 1.0, 0.55, 0.7, 0.4, 0.85, 0.5];
    final step = r.width / (pts.length - 1);
    for (var i = 0; i < pts.length; i++) {
      final x = r.left + i * step;
      final h = pts[i] * r.height * 0.52;
      canvas.drawLine(
        Offset(x, r.bottom - 1),
        Offset(x, r.bottom - h),
        paint,
      );
    }
  }

  /// Four minimalist piano keys — reference Acordes icon.
  void _drawChords(Canvas canvas, Rect r, Paint paint) {
    const keyCount = 4;
    final keyW = r.width * 0.14;
    final gap = (r.width - keyW * keyCount) / (keyCount + 1);
    final heights = [0.62, 0.78, 0.55, 0.88];

    for (var i = 0; i < keyCount; i++) {
      final left = r.left + gap + i * (keyW + gap);
      final top = r.bottom - r.height * heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, left + keyW, r.bottom - 1),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  /// Cyan EQ trace with three nodes — reference Sonido icon.
  void _drawEqGraph(Canvas canvas, Rect r, Paint paint) {
    final nodes = [
      Offset(r.left + r.width * 0.08, r.top + r.height * 0.62),
      Offset(r.left + r.width * 0.42, r.top + r.height * 0.28),
      Offset(r.right - r.width * 0.08, r.top + r.height * 0.20),
    ];

    canvas.drawPath(
      Path()
        ..moveTo(nodes[0].dx, nodes[0].dy)
        ..lineTo(nodes[1].dx, nodes[1].dy)
        ..lineTo(nodes[2].dx, nodes[2].dy),
      paint,
    );

    final fill = paint..style = PaintingStyle.fill..strokeWidth = 0;
    for (final node in nodes) {
      canvas.drawCircle(node, 2.0, fill);
    }
  }

  /// Orange VU gauge — reference Dinámica icon.
  void _drawDynamics(Canvas canvas, Rect r, Paint paint) {
    final arcRect = Rect.fromLTWH(r.left + 1, r.top + 3, r.width - 2, r.height - 4);
    const start = math.pi * 0.78;
    const sweep = math.pi * 1.44;

    canvas.drawArc(arcRect, start, sweep, false, paint);

    const needleAngle = math.pi * 1.12;
    final c = arcRect.center;
    canvas.drawLine(
      c,
      Offset(
        c.dx + math.cos(needleAngle) * arcRect.width * 0.36,
        c.dy + math.sin(needleAngle) * arcRect.width * 0.36,
      ),
      paint..strokeWidth = 1.0,
    );
    canvas.drawCircle(c, 1.4, paint..style = PaintingStyle.fill);
  }

  /// Thin-line over-ear headphones — reference Escucha Real icon.
  void _drawHeadphones(Canvas canvas, Rect r, Paint paint) {
    final band = Rect.fromLTWH(
      r.left + r.width * 0.06,
      r.top + r.height * 0.10,
      r.width * 0.88,
      r.height * 0.48,
    );
    canvas.drawArc(band, math.pi * 1.08, math.pi * 0.84, false, paint);

    void cup(double cx) {
      final outer = Rect.fromCenter(
        center: Offset(cx, r.top + r.height * 0.74),
        width: r.width * 0.26,
        height: r.height * 0.30,
      );
      canvas.drawOval(outer, paint);
      canvas.drawOval(outer.deflate(2.5), paint..strokeWidth = 0.9);
    }

    cup(r.left + r.width * 0.22);
    cup(r.right - r.width * 0.22);
  }

  void _drawFrequency(Canvas canvas, Rect r, Paint paint) {
    const heights = [0.35, 0.55, 0.75, 0.95, 0.65, 0.45];
    final step = r.width / (heights.length + 1);
    for (var i = 0; i < heights.length; i++) {
      final x = r.left + step * (i + 1);
      canvas.drawLine(
        Offset(x, r.bottom - 1),
        Offset(x, r.bottom - r.height * heights[i] * 0.55),
        paint,
      );
    }
  }

  void _drawLive(Canvas canvas, Rect r, Paint paint) {
    final c = Offset(r.center.dx, r.center.dy + 2);
    canvas.drawCircle(c, 2.2, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 4.0 + i * 4.5),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        paint..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(ModuleIconPainter old) => old.glow != glow;
}
