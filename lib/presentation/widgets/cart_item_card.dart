import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../providers/cart_item_provider.dart';
import 'animated_cart_item_wrapper.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Product? product;
  final Function(int) onQuantityChanged;
  final Function(double) onDiscountChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    this.product,
    required this.onQuantityChanged,
    required this.onDiscountChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCartItemWrapper(
      itemId: item.productId,
      child: Consumer<CartItemProvider>(
        builder: (context, cartItemProvider, child) {
          return _buildCartItemCard(context, cartItemProvider);
        },
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItemProvider cartItemProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final animationProvider = AnimatedCartItemWrapperProvider.of(context);
    
    final itemTotal = item.unitPrice * item.quantity;
    final discountAmount = itemTotal * (item.discount / 100);
    final finalTotal = itemTotal - discountAmount;

    return SlideTransition(
      position: animationProvider?.slideAnimation ?? 
                 const AlwaysStoppedAnimation(Offset.zero),
      child: FadeTransition(
        opacity: animationProvider?.fadeAnimation ?? 
                 const AlwaysStoppedAnimation(1.0),
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    _buildProductImage(context),
                    const SizedBox(width: 12),
                    // Product Info
                    Expanded(
                      child: _buildProductInfo(context, theme),
                    ),
                    // Remove Button
                    IconButton(
                      onPressed: () => cartItemProvider.showRemoveConfirmation(
                        context,
                        onRemove,
                      ),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quantity Controls
                _buildQuantityControls(context, theme),
                const SizedBox(height: 12),
                // Price and Discount Section
                _buildPriceSection(context, theme, itemTotal, discountAmount, finalTotal, cartItemProvider),
                // Discount Field (if shown)
                if (cartItemProvider.getShowDiscountField(item.productId)) ...[
                  const SizedBox(height: 12),
                  _buildDiscountField(context, theme, cartItemProvider),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: product?.imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage(context);
                },
              ),
            )
          : _buildPlaceholderImage(context),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Icon(
      Icons.inventory_2_outlined,
      size: 30,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildProductInfo(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product?.name ?? 'Produit inconnu',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (product?.category.isNotEmpty == true)
          Text(
            product!.category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Prix unitaire: ${item.unitPrice.toStringAsFixed(0)} FCFA',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Text(
          'Quantité:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: item.quantity > 1
                    ? () => onQuantityChanged(item.quantity - 1)
                    : null,
                icon: const Icon(Icons.remove),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  item.quantity.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onQuantityChanged(item.quantity + 1),
                icon: const Icon(Icons.add),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    ThemeData theme,
    double itemTotal,
    double discountAmount,
    double finalTotal,
    CartItemProvider cartItemProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total:'),
              Text(
                '${itemTotal.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (item.discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Remise (${item.discount}%):'),
                Text(
                  '-${discountAmount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${finalTotal.toStringAsFixed(0)} FCFA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => cartItemProvider.toggleDiscountField(item.productId),
                  icon: Icon(
                    cartItemProvider.getShowDiscountField(item.productId) 
                        ? Icons.expand_less 
                        : Icons.expand_more,
                  ),
                  label: const Text('Remise'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountField(BuildContext context, ThemeData theme, CartItemProvider cartItemProvider) {
    final discountController = cartItemProvider.getDiscountController(item.productId, item.discount);
    
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: discountController,
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
            final discount = double.tryParse(discountController.text) ?? 0.0;
            onDiscountChanged(discount.clamp(0.0, 100.0));
            cartItemProvider.hideDiscountField(item.productId);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}