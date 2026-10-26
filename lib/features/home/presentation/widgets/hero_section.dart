import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../painters/smooth_waveform_painter.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.waveAnimation,
    required this.scale,
  });

  final Animation<double> waveAnimation;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final titleSize = 32.0 * scale;
    final taglineSize = 19.0 * scale;

    return Column(
      children: [
        const EarLogo(),
        SizedBox(height: 14 * scale),
        TitleRow(titleSize: titleSize),
        SizedBox(height: 12 * scale),
        Tagline(taglineSize: taglineSize),
        SizedBox(height: 14 * scale),
        RepaintBoundary(
          child: AnimatedWaveform(animation: waveAnimation),
        ),
        SizedBox(height: 10 * scale),
        Text(
          'Desarrolla tu percepción. Mejora tus mezclas. Eleva tu sonido.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5 * scale,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.4,
            color: AppColors.textSecondary.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class EarLogo extends StatelessWidget {
  const EarLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final glowUnit = size / 56;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  blurRadius: 16 * glowUnit,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  blurRadius: 22 * glowUnit,
                  spreadRadius: 1 * glowUnit,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: Image.asset(
              AppAssets.bundle(AppAssets.logo),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              isAntiAlias: true,
            ),
          ),
        ],
      ),
    );
  }
}

class TitleRow extends StatelessWidget {
  const TitleRow({super.key, required this.titleSize});

  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.display(titleSize);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.purpleLight, AppColors.cyan, AppColors.blue],
          ).createShader(b),
          child: Text('EAR', style: style.copyWith(color: Colors.white)),
        ),
        Text(' TRAINER', style: style),
      ],
    );
  }
}

class Tagline extends StatelessWidget {
  const Tagline({super.key, required this.taglineSize});

  final double taglineSize;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.tagline(taglineSize);
    return Column(
      children: [
        Text('Entrena tus oídos.', textAlign: TextAlign.center, style: base),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: base,
            children: [
              const TextSpan(text: 'Siente la música '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.purpleLight, AppColors.blue],
                  ).createShader(b),
                  child: Text(
                    'diferente.',
                    style: base.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnimatedWaveform extends StatelessWidget {
  const AnimatedWaveform({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return SizedBox(
          height: 22,
          width: 130,
          child: CustomPaint(
            painter: SmoothWaveformPainter(phase: animation.value),
          ),
        );
      },
    );
  }
}
