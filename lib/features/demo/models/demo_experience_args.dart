import '../../onboarding/models/onboarding_option.dart';

class DemoExperienceArgs {
  const DemoExperienceArgs({
    required this.category,
    this.exerciseIndex = 0,
    this.practice = false,
  });

  final OnboardingOption category;
  final int exerciseIndex;

  /// Module practice: opens straight on the listening step and offers the
  /// next random exercise instead of the onboarding exit.
  final bool practice;
}
