import 'package:flutter/material.dart';

import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../models/app_language.dart';
import '../controllers/home_animations.dart';
import '../widgets/cinematic_background.dart';
import '../widgets/continue_training_section.dart';
import '../widgets/daily_challenge_section.dart';
import '../widgets/ear_today_section.dart';
import '../widgets/home_header_section.dart';
import '../widgets/light_continue_training_section.dart';
import '../widgets/login_prompt_banner.dart';
import '../widgets/modules_carousel_section.dart';
import '../widgets/progress_section.dart';
import '../widgets/recommended_listen_section.dart';

/// Training hub — light mode before login, full experience after sign-in.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  AppLanguage _language = AppLanguage.es;
  late final HomeAnimations _animations;

  @override
  void initState() {
    super.initState();
    _animations = HomeAnimations(vsync: this);
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  void _refreshAfterSessionChange() {
    if (mounted) setState(() {});
  }

  Future<void> _openLogin() async {
    await AppNavigator.openLogin(context);
    _refreshAfterSessionChange();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = MockSession.isLightMode;
    final showLoginPrompt = MockSession.shouldShowLoginPrompt;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CinematicBackground(ambient: _animations.ambient),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = HomeLayoutMetrics.fromConstraints(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );

                return Center(
                  child: SizedBox(
                    width: layout.contentWidth,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        8,
                        layout.horizontalPadding,
                        layout.bottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeInSection(
                            child: HomeHeaderSection(
                              language: _language,
                              onLanguageChanged: (l) => setState(() => _language = l),
                              onProfileTap: isLight ? _openLogin : null,
                              profileLocked: isLight,
                            ),
                          ),
                          if (showLoginPrompt) ...[
                            SizedBox(height: 24 * layout.scale),
                            LoginPromptBanner(
                              onDismiss: () {
                                MockSession.dismissLoginPrompt();
                                _refreshAfterSessionChange();
                              },
                              onSignedIn: _refreshAfterSessionChange,
                            ),
                          ],
                          FadeInSection(
                            delay: const Duration(milliseconds: 60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 28 * layout.scale),
                                const EarTodaySection(),
                                SizedBox(height: 32 * layout.scale),
                                MockSession.hasFullAccess
                                    ? const ContinueTrainingSection()
                                    : isLight
                                        ? LightContinueTrainingSection(onLoginTap: _openLogin)
                                        : const SizedBox.shrink(),
                                SizedBox(height: 32 * layout.scale),
                                DailyChallengeSection(
                                  onChallengeReturn: _refreshAfterSessionChange,
                                  onLoginRequired: _refreshAfterSessionChange,
                                ),
                                SizedBox(height: 32 * layout.scale),
                                const RecommendedListenSection(),
                                SizedBox(height: 36 * layout.scale),
                                ModulesCarouselSection(
                                  modules: MockSession.homeModules,
                                  onModuleReturn: _refreshAfterSessionChange,
                                ),
                                SizedBox(height: 36 * layout.scale),
                                ProgressSection(locked: isLight, onLoginTap: _openLogin),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
