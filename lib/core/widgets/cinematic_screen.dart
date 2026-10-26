import 'package:flutter/material.dart';

import '../../features/home/presentation/controllers/home_animations.dart';
import '../../features/home/presentation/widgets/cinematic_background.dart';

/// Full-screen cinematic wrapper shared across flows.
class CinematicScreen extends StatefulWidget {
  const CinematicScreen({
    super.key,
    required this.child,
    this.animateBackground = true,
  });

  final Widget child;
  final bool animateBackground;

  @override
  State<CinematicScreen> createState() => _CinematicScreenState();
}

class _CinematicScreenState extends State<CinematicScreen>
    with TickerProviderStateMixin {
  HomeAnimations? _animations;

  @override
  void initState() {
    super.initState();
    if (widget.animateBackground) {
      _animations = HomeAnimations(vsync: this);
    }
  }

  @override
  void dispose() {
    _animations?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_animations != null)
            CinematicBackground(ambient: _animations!.ambient)
          else
            const CinematicBackground(ambient: AlwaysStoppedAnimation(0.5)),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}
