import 'package:flutter/material.dart';

class CartScreenProvider extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController taxController = TextEditingController();

  void showProductSelector(BuildContext context) {
    // TODO: Implement product selector dialog or navigate to products screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélecteur de produits à implémenter')),
    );
  }

  void showClearCartConfirmation(BuildContext context, VoidCallback onClear) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider le panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClear();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  void processCheckout(BuildContext context) {
    // TODO: Implement checkout process (create invoice, process payment, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processus de finalisation à implémenter')),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    discountController.dispose();
    taxController.dispose();
    super.dispose();
  }
}