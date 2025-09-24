import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/invoice.dart';
import 'invoice_provider.dart';
import 'cart_provider.dart';
import 'product_provider.dart';

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
      final productProvider = context.read<ProductProvider>();
      
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

      final cart = cartProvider.currentCart!;
      
      // Actualiser les données des produits pour avoir les stocks les plus récents
      await productProvider.refresh();
      
      // Vérifier que tous les produits ont suffisamment de stock avant de procéder
      for (final item in cart.items) {
        // Obtenir les informations les plus récentes du produit
        final currentProduct = productProvider.getProductById(item.product.id);
        if (currentProduct == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produit ${item.product.name} non trouvé'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (item.quantity > currentProduct.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock insuffisant pour ${item.product.name}. Disponible: ${currentProduct.quantity}, Demandé: ${item.quantity}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Vérifier que le produit n'est pas en rupture de stock
        if (currentProduct.quantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.product.name} est en rupture de stock'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Créer la facture à partir du panier
      final invoice = await invoiceProvider.createInvoiceFromCart(
        cart: cart,
      );

      if (invoice != null) {
        // Marquer la facture comme payée (paiement en espèces par défaut)
        await invoiceProvider.markInvoiceAsPaid(invoice.id, PaymentMethod.cash);
        
        // Diminuer les stocks pour chaque produit vendu
        try {
          for (final item in cart.items) {
            await productProvider.adjustStock(item.product.id, -item.quantity);
          }
        } catch (e) {
          // Si erreur lors de la diminution des stocks, afficher un avertissement
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vente finalisée mais erreur lors de la mise à jour des stocks: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        // Vider le panier après le paiement
        await cartProvider.clearCart();
        
        // Actualiser les produits pour refléter les nouveaux stocks dans l'interface
        await productProvider.refresh();
        
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