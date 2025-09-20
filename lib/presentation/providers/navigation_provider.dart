import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void navigateToHome() {
    setCurrentIndex(0);
  }
  
  void navigateToProducts() {
    setCurrentIndex(1);
  }
  
  void navigateToCart() {
    setCurrentIndex(2);
  }
}