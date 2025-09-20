import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/theme_toggle_provider.dart';
import 'animated_theme_toggle_wrapper.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedThemeToggleWrapper(
      child: Consumer2<ThemeProvider, ThemeToggleProvider>(
        builder: (context, themeProvider, themeToggleProvider, child) {
          return _buildThemeToggleButton(context, themeProvider, themeToggleProvider);
        },
      ),
    );
  }

  Widget _buildThemeToggleButton(
    BuildContext context, 
    ThemeProvider themeProvider, 
    ThemeToggleProvider themeToggleProvider
  ) {
    final animationProvider = AnimatedThemeToggleWrapperProvider.of(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system && 
         MediaQuery.of(context).platformBrightness == Brightness.dark);

    return AnimatedBuilder(
      animation: animationProvider?.rotationAnimation ?? 
                 const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + ((animationProvider?.scaleAnimation.value ?? 1.0) - 1.0) * 0.1,
          child: FloatingActionButton(
            onPressed: () {
              animationProvider?.triggerAnimation();
              themeToggleProvider.startAnimation();
              themeProvider.toggleTheme();
            },
            backgroundColor: isDark 
              ? AppColors.primaryDark 
              : AppColors.primaryLight,
            elevation: 8,
            child: Transform.rotate(
              angle: (animationProvider?.rotationAnimation.value ?? 0.0) * 2 * 3.14159,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  themeProvider.themeModeIcon,
                  key: ValueKey(themeProvider.themeMode),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}