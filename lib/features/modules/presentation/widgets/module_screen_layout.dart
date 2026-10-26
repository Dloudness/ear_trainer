import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../home/presentation/controllers/home_animations.dart';
import '../../../home/presentation/widgets/cinematic_background.dart';

class ModuleScreenLayout extends StatefulWidget {
  const ModuleScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  State<ModuleScreenLayout> createState() => _ModuleScreenLayoutState();
}

class _ModuleScreenLayoutState extends State<ModuleScreenLayout>
    with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CinematicBackground(ambient: _animations.ambient),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CinematicNavBar(
                    showHome: MockSession.hasEnteredHub,
                    onHome: () => AppNavigator.goHome(context),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.title, style: AppTypography.display(24)),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: widget.children.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => widget.children[i],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
