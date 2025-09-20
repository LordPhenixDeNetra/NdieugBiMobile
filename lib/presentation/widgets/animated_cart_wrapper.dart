import 'package:flutter/material.dart';

class AnimatedCartWrapper extends StatefulWidget {
  final Widget child;
  
  const AnimatedCartWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedCartWrapper> createState() => _AnimatedCartWrapperState();
}

class _AnimatedCartWrapperState extends State<AnimatedCartWrapper>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _checkoutAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _checkoutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkoutAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start the main animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkoutAnimationController.dispose();
    super.dispose();
  }

  void triggerCheckoutAnimation() {
    _checkoutAnimationController.forward().then((_) {
      _checkoutAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

// Provider to access animation methods
class AnimatedCartWrapperProvider extends InheritedWidget {
  final void Function() triggerCheckoutAnimation;
  final Animation<double> fadeAnimation;
  
  const AnimatedCartWrapperProvider({
    super.key,
    required this.triggerCheckoutAnimation,
    required this.fadeAnimation,
    required super.child,
  });

  static AnimatedCartWrapperProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AnimatedCartWrapperProvider>();
  }

  @override
  bool updateShouldNotify(AnimatedCartWrapperProvider oldWidget) {
    return false;
  }
}