import 'package:flutter/material.dart';

class SearchBarProvider extends ChangeNotifier {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _hasTextStates = {};

  // Get or create text controller for a specific search bar
  TextEditingController getController(String searchBarId, {TextEditingController? existingController}) {
    if (existingController != null) {
      _controllers[searchBarId] = existingController;
      _hasTextStates[searchBarId] = existingController.text.isNotEmpty;
      existingController.addListener(() => _onTextChanged(searchBarId));
      return existingController;
    }
    
    if (!_controllers.containsKey(searchBarId)) {
      _controllers[searchBarId] = TextEditingController();
      _hasTextStates[searchBarId] = false;
      _controllers[searchBarId]!.addListener(() => _onTextChanged(searchBarId));
    }
    return _controllers[searchBarId]!;
  }

  // Get text state for a specific search bar
  bool getHasText(String searchBarId) {
    return _hasTextStates[searchBarId] ?? false;
  }

  // Handle text changes
  void _onTextChanged(String searchBarId) {
    final controller = _controllers[searchBarId];
    if (controller != null) {
      final hasText = controller.text.isNotEmpty;
      if (hasText != _hasTextStates[searchBarId]) {
        _hasTextStates[searchBarId] = hasText;
        notifyListeners();
      }
    }
  }

  // Clear text for a specific search bar
  void clearText(String searchBarId, VoidCallback? onClear) {
    final controller = _controllers[searchBarId];
    if (controller != null) {
      controller.clear();
      onClear?.call();
    }
  }

  // Remove search bar from tracking
  void removeSearchBar(String searchBarId) {
    _controllers[searchBarId]?.dispose();
    _controllers.remove(searchBarId);
    _hasTextStates.remove(searchBarId);
    notifyListeners();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _hasTextStates.clear();
    super.dispose();
  }
}