import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Typography hierarchy for listening exercises — question first, instruction quiet.
class ExerciseFocusHeader extends StatelessWidget {
  const ExerciseFocusHeader({
    super.key,
    required this.question,
    this.instruction,
    this.hint,
    this.questionSize = 26,
    this.center = true,
  });

  final String question;
  final String? instruction;
  final String? hint;
  final double questionSize;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (instruction != null) ...[
          Text(
            instruction!,
            textAlign: align,
            style: AppTypography.exerciseInstruction,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          question,
          textAlign: align,
          style: AppTypography.exerciseQuestion(questionSize),
        ),
        if (hint != null) ...[
          const SizedBox(height: 12),
          Text(
            hint!,
            textAlign: align,
            style: AppTypography.exerciseHint,
          ),
        ],
      ],
    );
  }
}

/// Soft playback state line inside exercise cards.
class ExercisePlaybackHint extends StatelessWidget {
  const ExercisePlaybackHint({
    super.key,
    required this.playing,
    this.idleText = 'Toca para escuchar',
    this.playingText = 'Reproduciendo…',
  });

  final bool playing;
  final String idleText;
  final String playingText;

  @override
  Widget build(BuildContext context) {
    return Text(
      playing ? playingText : idleText,
      textAlign: TextAlign.center,
      style: AppTypography.exerciseHint.copyWith(fontStyle: FontStyle.normal),
    );
  }
}
