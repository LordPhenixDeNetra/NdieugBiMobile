import 'package:flutter/material.dart';

class AnimatedSearchBarWrapper extends StatefulWidget {
  final Widget child;
  final String searchBarId;

  const AnimatedSearchBarWrapper({
    Key? key,
    required this.child,
    required this.searchBarId,
  }) : super(key: key);

  @override
  State<AnimatedSearchBarWrapper> createState() => _AnimatedSearchBarWrapperState();
}

class _AnimatedSearchBarWrapperState extends State<AnimatedSearchBarWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void animateIn() {
    _animationController.forward();
  }

  void animateOut() {
    _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSearchBarWrapperProvider(
      scaleAnimation: _scaleAnimation,
      animateIn: animateIn,
      animateOut: animateOut,
      child: widget.child,
    );
  }
}

class AnimatedSearchBarWrapperProvider extends InheritedWidget {
  final Animation<double> scaleAnimation;
  final VoidCallback animateIn;
  final VoidCallback animateOut;

  const AnimatedSearchBarWrapperProvider({
    Key? key,
    required this.scaleAnimation,
    required this.animateIn,
    required this.animateOut,
    required Widget child,
  }) : super(key: key, child: child);

  static AnimatedSearchBarWrapperProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AnimatedSearchBarWrapperProvider>();
  }

  @override
  bool updateShouldNotify(AnimatedSearchBarWrapperProvider oldWidget) {
    return scaleAnimation != oldWidget.scaleAnimation;
  }
}