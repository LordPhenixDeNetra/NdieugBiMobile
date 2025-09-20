import 'package:flutter/material.dart';

class CartItemProvider extends ChangeNotifier {
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, bool> _showDiscountFields = {};

  // Get or create discount controller for a specific item
  TextEditingController getDiscountController(String itemId, double initialDiscount) {
    if (!_discountControllers.containsKey(itemId)) {
      _discountControllers[itemId] = TextEditingController(text: initialDiscount.toString());
    }
    return _discountControllers[itemId]!;
  }

  // Get discount field visibility for a specific item
  bool getShowDiscountField(String itemId) {
    return _showDiscountFields[itemId] ?? false;
  }

  // Toggle discount field visibility for a specific item
  void toggleDiscountField(String itemId) {
    _showDiscountFields[itemId] = !(_showDiscountFields[itemId] ?? false);
    notifyListeners();
  }

  // Hide discount field for a specific item
  void hideDiscountField(String itemId) {
    _showDiscountFields[itemId] = false;
    notifyListeners();
  }

  // Show remove confirmation dialog
  void showRemoveConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet article du panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // Clean up controllers for removed items
  void removeItem(String itemId) {
    _discountControllers[itemId]?.dispose();
    _discountControllers.remove(itemId);
    _showDiscountFields.remove(itemId);
    notifyListeners();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _discountControllers.values) {
      controller.dispose();
    }
    _discountControllers.clear();
    _showDiscountFields.clear();
    super.dispose();
  }
}