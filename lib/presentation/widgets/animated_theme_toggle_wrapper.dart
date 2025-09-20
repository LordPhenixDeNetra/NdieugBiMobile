import 'package:flutter/material.dart';

class AnimatedThemeToggleWrapper extends StatefulWidget {
  final Widget child;

  const AnimatedThemeToggleWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedThemeToggleWrapper> createState() => _AnimatedThemeToggleWrapperState();
}

class _AnimatedThemeToggleWrapperState extends State<AnimatedThemeToggleWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  void triggerAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedThemeToggleWrapperProvider(
      rotationAnimation: _rotationAnimation,
      scaleAnimation: _scaleAnimation,
      triggerAnimation: triggerAnimation,
      child: widget.child,
    );
  }
}

class AnimatedThemeToggleWrapperProvider extends InheritedWidget {
  final Animation<double> rotationAnimation;
  final Animation<double> scaleAnimation;
  final VoidCallback triggerAnimation;

  const AnimatedThemeToggleWrapperProvider({
    Key? key,
    required this.rotationAnimation,
    required this.scaleAnimation,
    required this.triggerAnimation,
    required Widget child,
  }) : super(key: key, child: child);

  static AnimatedThemeToggleWrapperProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AnimatedThemeToggleWrapperProvider>();
  }

  @override
  bool updateShouldNotify(AnimatedThemeToggleWrapperProvider oldWidget) {
    return rotationAnimation != oldWidget.rotationAnimation ||
           scaleAnimation != oldWidget.scaleAnimation;
  }
}