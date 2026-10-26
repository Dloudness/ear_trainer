import 'package:flutter/material.dart';

import '../../models/module_icon_type.dart';
import '../painters/module_icon_painter.dart';

/// Compact neon line icon for dashboard-style module cards.
class ModuleNeonIcon extends StatelessWidget {
  const ModuleNeonIcon({
    super.key,
    required this.type,
    required this.accentStart,
    required this.accentEnd,
    required this.isActive,
    this.size = 46,
  });

  final ModuleIconType type;
  final Color accentStart;
  final Color accentEnd;
  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(
            color: accentStart.withValues(alpha: isActive ? 0.22 : 0.1),
            width: 0.6,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentStart.withValues(alpha: isActive ? 0.1 : 0.05),
              accentEnd.withValues(alpha: isActive ? 0.04 : 0.02),
            ],
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: accentStart.withValues(alpha: 0.14),
                blurRadius: 14,
                spreadRadius: -2,
              ),
          ],
        ),
        child: CustomPaint(
          painter: ModuleIconPainter(
            type: type,
            accentStart: accentStart,
            accentEnd: accentEnd,
            glow: isActive,
          ),
        ),
      ),
    );
  }
}
