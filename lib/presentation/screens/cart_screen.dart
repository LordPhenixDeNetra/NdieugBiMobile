import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/cart_screen_provider.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/animated_cart_wrapper.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedCartWrapper(
      child: Consumer<CartScreenProvider>(
        builder: (context, cartScreenProvider, child) {
          return _buildCartScreen(context, cartScreenProvider);
        },
      ),
    );
  }

  Widget _buildCartScreen(BuildContext context, CartScreenProvider cartScreenProvider) {
    return Consumer3<ConnectivityProvider, CartProvider, ProductProvider>(
      builder: (context, connectivityProvider, cartProvider, productProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            controller: cartScreenProvider.scrollController,
            slivers: [
              _buildAppBar(context, cartProvider, cartScreenProvider),
              if (!connectivityProvider.isOnline)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.orange,
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Mode hors ligne',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => connectivityProvider.checkConnectivity(),
                          child: const Text(
                            'Réessayer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildCartContent(context, cartProvider, productProvider, cartScreenProvider),
            ],
          ),
          bottomNavigationBar: Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) return const SizedBox.shrink();
              
              return _buildCheckoutSection(context, cartProvider, cartScreenProvider);
            },
          ),
          floatingActionButton: Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) {
                return FloatingActionButton.extended(
                  onPressed: () => cartScreenProvider.showProductSelector(context),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Ajouter Produits'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, CartProvider cartProvider, CartScreenProvider cartScreenProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panier',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            if (cartProvider.hasCart)
              Text(
                '${cartProvider.itemCount} article${cartProvider.itemCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (cartProvider.hasCart && !cartProvider.isEmpty)
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => cartScreenProvider.showClearCartConfirmation(
              context,
              () => cartProvider.clearCart(),
            ),
            tooltip: 'Vider le panier',
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: cartProvider.isLoading 
              ? null 
              : () => cartProvider.refresh(),
        ),
      ],
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    CartProvider cartProvider,
    ProductProvider productProvider,
    CartScreenProvider cartScreenProvider,
  ) {
    if (cartProvider.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (cartProvider.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                cartProvider.error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => cartProvider.refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (cartProvider.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Panier vide',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez des produits pour commencer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => cartScreenProvider.showProductSelector(context),
                child: const Text('Parcourir les produits'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCartItems(context, cartProvider, productProvider),
              const SizedBox(height: 16),
              _buildDiscountSection(context, cartProvider, cartScreenProvider),
              const SizedBox(height: 16),
              _buildTaxSection(context, cartProvider, cartScreenProvider),
              const SizedBox(height: 16),
              _buildPriceSummary(context, cartProvider),
              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCartItems(
    BuildContext context,
    CartProvider cartProvider,
    ProductProvider productProvider,
  ) {
    final cart = cartProvider.currentCart!;
    
    return Column(
      children: cart.items.map((item) {
        final product = productProvider.getProductById(item.productId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CartItemCard(
            item: item,
            product: product,
            onQuantityChanged: (quantity) {
              if (quantity <= 0) {
                cartProvider.removeProduct(item.productId);
              } else {
                cartProvider.updateQuantity(item.productId, quantity);
              }
            },
            onDiscountChanged: (discount) {
              cartProvider.updateItemDiscount(item.productId, discount);
            },
            onRemove: () => cartProvider.removeProduct(item.productId),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscountSection(BuildContext context, CartProvider cartProvider, CartScreenProvider cartScreenProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remise globale',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: cartScreenProvider.discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Remise (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final discount = double.tryParse(cartScreenProvider.discountController.text) ?? 0.0;
                    cartProvider.applyGlobalDiscount(discount);
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSection(BuildContext context, CartProvider cartProvider, CartScreenProvider cartScreenProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: cartScreenProvider.taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Taux de taxe (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final taxRate = double.tryParse(cartScreenProvider.taxController.text) ?? 0.0;
                    cartProvider.setTaxRate(taxRate);
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context, CartProvider cartProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             _buildPriceRow(context, 'Sous-total', cartProvider.subtotal),
             if (cartProvider.totalDiscount > 0)
               _buildPriceRow(context, 'Remise', -cartProvider.totalDiscount, isDiscount: true),
             if (cartProvider.taxAmount > 0)
               _buildPriceRow(context, 'Taxe', cartProvider.taxAmount),
             const Divider(),
             _buildPriceRow(context, 'Total', cartProvider.total, isTotal: true),
           ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal 
                ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: isTotal 
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : isDiscount
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green)
                    : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cartProvider, CartScreenProvider cartScreenProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cartProvider.total.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => cartScreenProvider.showProductSelector(context),
                    child: const Text('Ajouter Produits'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: cartProvider.isLoading 
                        ? null 
                        : () => cartScreenProvider.processCheckout(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: cartProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Finaliser la vente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}