import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/invoice.dart';
import 'invoice_provider.dart';
import 'cart_provider.dart';

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

  void processCheckout(BuildContext context) async {
    try {
      final cartProvider = context.read<CartProvider>();
      final invoiceProvider = context.read<InvoiceProvider>();
      
      // Vérifier si le panier n'est pas vide
      if (cartProvider.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le panier est vide'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Créer la facture à partir du panier
      final invoice = await invoiceProvider.createInvoiceFromCart(
        cart: cartProvider.currentCart!,
      );

      if (invoice != null) {
        // Marquer la facture comme payée (paiement en espèces par défaut)
        await invoiceProvider.markInvoiceAsPaid(invoice.id, PaymentMethod.cash);
        
        // Vider le panier après le paiement
        await cartProvider.clearCart();
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vente finalisée avec succès! Facture: ${invoice.invoiceNumber}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // Naviguer vers l'écran de facture
                Navigator.of(context).pushNamed('/invoice', arguments: invoice.id);
              },
            ),
          ),
        );
      } else {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: ${invoiceProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs inattendues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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