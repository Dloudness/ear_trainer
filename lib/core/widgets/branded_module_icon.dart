import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Premium PNG module icon with subtle cinematic glow frame.
class BrandedModuleIcon extends StatelessWidget {
  const BrandedModuleIcon({
    super.key,
    required this.assetPath,
    required this.accentStart,
    required this.accentEnd,
    this.isActive = false,
    this.size = 46,
    this.padding = 8,
  });

  final String assetPath;
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
          child: Image.asset(
            AppAssets.bundle(assetPath),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            isAntiAlias: true,
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
    required this.assetPath,
    required this.accent,
    this.size = 32,
    this.isActive = false,
  });

  final String assetPath;
  final Color accent;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return BrandedModuleIcon(
      assetPath: assetPath,
      accentStart: accent,
      accentEnd: accent,
      isActive: isActive,
      size: size,
      padding: size * 0.16,
    );
  }
}
