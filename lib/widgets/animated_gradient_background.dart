import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Much faster
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                Color.lerp(
                  AppTheme.primary.withValues(alpha: 0.5), 
                  AppTheme.isDarkLike ? const Color(0xFF00E5FF).withValues(alpha: 0.3) : AppTheme.surfaceLight.withValues(alpha: 0.8), 
                  _controller.value
                )!,
                AppTheme.background,
                Color.lerp(
                  AppTheme.isDarkLike ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : AppTheme.primary.withValues(alpha: 0.3), 
                  AppTheme.primary.withValues(alpha: AppTheme.isDarkLike ? 0.7 : 0.4), 
                  _controller.value
                )!,
              ],
            ),
          ),
        );
      },
    );
  }
}
