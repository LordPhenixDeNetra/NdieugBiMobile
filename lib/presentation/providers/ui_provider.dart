import 'package:flutter/material.dart';

class UiProvider extends ChangeNotifier {
  // Animation controllers map pour différents écrans
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, ScrollController> _scrollControllers = {};
  
  // États visuels
  bool _showFab = true;
  bool _isSearchExpanded = false;
  String _selectedSortOption = 'name';
  String _selectedCategory = 'all';
  
  // Getters
  bool get showFab => _showFab;
  bool get isSearchExpanded => _isSearchExpanded;
  String get selectedSortOption => _selectedSortOption;
  String get selectedCategory => _selectedCategory;
  
  // Animation controllers
  AnimationController? getAnimationController(String key) => _animationControllers[key];
  ScrollController? getScrollController(String key) => _scrollControllers[key];
  
  // Setters
  void setShowFab(bool show) {
    if (_showFab != show) {
      _showFab = show;
      notifyListeners();
    }
  }
  
  void setSearchExpanded(bool expanded) {
    if (_isSearchExpanded != expanded) {
      _isSearchExpanded = expanded;
      notifyListeners();
    }
  }
  
  void setSortOption(String option) {
    if (_selectedSortOption != option) {
      _selectedSortOption = option;
      notifyListeners();
    }
  }
  
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }
  
  // Animation controller management
  void registerAnimationController(String key, AnimationController controller) {
    _animationControllers[key] = controller;
  }
  
  void registerScrollController(String key, ScrollController controller) {
    _scrollControllers[key] = controller;
  }
  
  void disposeAnimationController(String key) {
    _animationControllers[key]?.dispose();
    _animationControllers.remove(key);
  }
  
  void disposeScrollController(String key) {
    _scrollControllers[key]?.dispose();
    _scrollControllers.remove(key);
  }
  
  // Scroll handling
  void handleScroll(String key, double offset) {
    if (key == 'products') {
      // Toujours afficher le FAB pour les produits
      if (!_showFab) {
        setShowFab(true);
      }
    }
  }
  
  // Reset state
  void reset() {
    _showFab = true;
    _isSearchExpanded = false;
    _selectedSortOption = 'name';
    _selectedCategory = 'all';
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    
    // Dispose all scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    super.dispose();
  }
}