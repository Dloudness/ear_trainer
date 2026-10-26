import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class FooterQuote extends StatelessWidget {
  const FooterQuote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientQuoteMark(isOpening: true),
        const SizedBox(width: 2),
        Flexible(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'No se trata solo de escuchar. Se trata de '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.blue, AppColors.cyan],
                    ).createShader(b),
                    child: const Text(
                      'entender',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' lo que escuchas.'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        const GradientQuoteMark(isOpening: false),
      ],
    );
  }
}

class GradientQuoteMark extends StatelessWidget {
  const GradientQuoteMark({super.key, required this.isOpening});

  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    return Text(
      '"',
      style: TextStyle(
        fontSize: 28,
        height: 0.75,
        fontWeight: FontWeight.w200,
        foreground: Paint()
          ..shader = LinearGradient(
            colors: isOpening
                ? [AppColors.purpleLight, AppColors.blue]
                : [AppColors.blue, AppColors.purpleLight],
          ).createShader(const Rect.fromLTWH(0, 0, 24, 36)),
      ),
    );
  }
}
