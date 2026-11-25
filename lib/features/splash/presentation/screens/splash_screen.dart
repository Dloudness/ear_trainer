import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/orb_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    // A registered listener goes straight to their progress.
    Navigator.pushReplacementNamed(
      context,
      MockSession.hasAccount ? AppRoutes.home : AppRoutes.welcome,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OrbLogo(size: 120),
            const SizedBox(height: 24),
            Text(
              'EAR TRAINER',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 6,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.cyan.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
