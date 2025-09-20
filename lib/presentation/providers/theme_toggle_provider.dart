import 'package:flutter/material.dart';

class ThemeToggleProvider extends ChangeNotifier {
  bool _isAnimating = false;

  bool get isAnimating => _isAnimating;

  // Trigger animation state
  void startAnimation() {
    _isAnimating = true;
    notifyListeners();
    
    // Reset animation state after animation completes
    Future.delayed(const Duration(milliseconds: 600), () {
      _isAnimating = false;
      notifyListeners();
    });
  }
}