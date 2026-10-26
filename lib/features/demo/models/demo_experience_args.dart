import '../../onboarding/models/onboarding_option.dart';

class DemoExperienceArgs {
  const DemoExperienceArgs({
    required this.category,
    this.exerciseIndex = 0,
  });

  final OnboardingOption category;
  final int exerciseIndex;
}
