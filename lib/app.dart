import 'package:flutter/material.dart';

import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_motion.dart';
import 'features/challenge/presentation/screens/daily_challenge_screen.dart';
import 'features/demo/models/demo_experience_args.dart';
import 'features/demo/presentation/screens/demo_experience_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/modules/models/placeholder_exercise_args.dart';
import 'features/modules/presentation/screens/dinamica_screen.dart';
import 'features/modules/presentation/screens/escucha_real_screen.dart';
import 'features/modules/presentation/screens/frecuencias_screen.dart';
import 'features/modules/presentation/screens/musical_training_screen.dart';
import 'features/modules/presentation/screens/placeholder_exercise_screen.dart';
import 'features/onboarding/models/onboarding_option.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';

class EarTrainerApp extends StatelessWidget {
  const EarTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ear Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.welcome => const WelcomeScreen(),
      AppRoutes.onboarding => const OnboardingScreen(),
      AppRoutes.demo => () {
          final args = settings.arguments;
          if (args is DemoExperienceArgs) {
            return DemoExperienceScreen(
              category: args.category,
              exerciseIndex: args.exerciseIndex,
            );
          }
          if (args is OnboardingOption) {
            return DemoExperienceScreen(category: args);
          }
          return const DemoExperienceScreen();
        }(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.home => const HomeScreen(),
      AppRoutes.dailyChallenge => const DailyChallengeScreen(),
      AppRoutes.exercise => PlaceholderExerciseScreen(
          args: settings.arguments! as PlaceholderExerciseArgs,
        ),
      AppRoutes.moduleFrecuencias => const FrecuenciasScreen(),
      AppRoutes.moduleDinamica => const DinamicaScreen(),
      AppRoutes.moduleMusical => const MusicalTrainingScreen(),
      AppRoutes.moduleEscuchaReal => const EscuchaRealScreen(),
      _ => const SplashScreen(),
    };

    return AppTransitions.cinematicRoute(
      settings: settings,
      screen: screen,
    );
  }
}
