import 'package:flutter/material.dart';

class AnimatedCartItemWrapper extends StatefulWidget {
  final Widget child;
  final String itemId;

  const AnimatedCartItemWrapper({
    Key? key,
    required this.child,
    required this.itemId,
  }) : super(key: key);

  @override
  State<AnimatedCartItemWrapper> createState() => _AnimatedCartItemWrapperState();
}

class _AnimatedCartItemWrapperState extends State<AnimatedCartItemWrapper>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCartItemWrapperProvider(
      slideAnimation: _slideAnimation,
      fadeAnimation: _fadeAnimation,
      slideController: _slideController,
      fadeController: _fadeController,
      child: widget.child,
    );
  }
}

class AnimatedCartItemWrapperProvider extends InheritedWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final AnimationController slideController;
  final AnimationController fadeController;

  const AnimatedCartItemWrapperProvider({
    Key? key,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.slideController,
    required this.fadeController,
    required Widget child,
  }) : super(key: key, child: child);

  static AnimatedCartItemWrapperProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AnimatedCartItemWrapperProvider>();
  }

  @override
  bool updateShouldNotify(AnimatedCartItemWrapperProvider oldWidget) {
    return slideAnimation != oldWidget.slideAnimation ||
           fadeAnimation != oldWidget.fadeAnimation;
  }
}