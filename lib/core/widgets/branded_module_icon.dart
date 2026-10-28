import 'package:flutter/material.dart';

/// Single-color module mark with a soft accent glow.
class BrandedModuleIcon extends StatelessWidget {
  const BrandedModuleIcon({
    super.key,
    required this.icon,
    required this.accentStart,
    required this.accentEnd,
    this.isActive = false,
    this.size = 46,
    this.padding = 4,
  });

  final IconData icon;
  final Color accentStart;
  final Color accentEnd;
  final bool isActive;
  final double size;
  final double padding;

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
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(
            icon,
            size: size - padding * 2,
            color: accentStart,
            shadows: [
              Shadow(
                color: accentStart.withValues(alpha: isActive ? 0.65 : 0.42),
                blurRadius: isActive ? 12 : 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact inline branded icon for list rows and section headers.
class BrandedModuleIconInline extends StatelessWidget {
  const BrandedModuleIconInline({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 32,
    this.isActive = false,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return BrandedModuleIcon(
      icon: icon,
      accentStart: accent,
      accentEnd: accent,
      isActive: isActive,
      size: size,
      padding: size * 0.1,
    );
  }
}
