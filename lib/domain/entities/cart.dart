import 'package:equatable/equatable.dart';
import 'cart_item.dart';
import 'product.dart';

class Cart extends Equatable {
  final String id;
  final List<CartItem> items;
  final double globalDiscount;
  final double taxRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? customerId;
  final Map<String, dynamic>? metadata;

  const Cart({
    required this.id,
    this.items = const [],
    this.globalDiscount = 0.0,
    this.taxRate = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.customerId,
    this.metadata,
  });

  // Getters for calculated properties
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount) + globalDiscountAmount;
  double get globalDiscountAmount => subtotal * (globalDiscount / 100);
  double get taxableAmount => subtotal - totalDiscount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get total => taxableAmount + taxAmount;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  // Copy with method for immutability
  Cart copyWith({
    String? id,
    List<CartItem>? items,
    double? globalDiscount,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) {
    return Cart(
      id: id ?? this.id,
      items: items ?? this.items,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Add item to cart
  Cart addItem(Product product, {int quantity = 1, double? customPrice}) {
    final existingItemIndex = items.indexWhere((item) => item.product.id == product.id);
    final unitPrice = customPrice ?? product.price;
    
    if (existingItemIndex != -1) {
      // Update existing item quantity
      final existingItem = items[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;
      
      if (newQuantity > product.quantity) {
        throw Exception('Quantité demandée supérieure au stock disponible');
      }
      
      final updatedItem = existingItem.updateQuantity(newQuantity);
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingItemIndex] = updatedItem;
      
      return copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    } else {
      // Add new item
      if (quantity > product.quantity) {
        throw Exception('Quantité demandée supérieure au stock disponible');
      }
      
      final newItem = CartItem(
        id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        quantity: quantity,
        unitPrice: unitPrice,
        addedAt: DateTime.now(),
      );
      
      return copyWith(
        items: [...items, newItem],
        updatedAt: DateTime.now(),
      );
    }
  }

  // Remove item from cart
  Cart removeItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  // Update item quantity
  Cart updateItemQuantity(String itemId, int quantity) {
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw Exception('Article non trouvé dans le panier');
    }
    
    if (quantity <= 0) {
      return removeItem(itemId);
    }
    
    final updatedItem = items[itemIndex].updateQuantity(quantity);
    final updatedItems = List<CartItem>.from(items);
    updatedItems[itemIndex] = updatedItem;
    
    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  // Apply discount to specific item
  Cart applyItemDiscount(String itemId, double discountPercentage) {
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw Exception('Article non trouvé dans le panier');
    }
    
    final updatedItem = items[itemIndex].applyDiscount(discountPercentage);
    final updatedItems = List<CartItem>.from(items);
    updatedItems[itemIndex] = updatedItem;
    
    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  // Apply global discount
  Cart applyGlobalDiscount(double discountPercentage) {
    if (discountPercentage < 0 || discountPercentage > 100) {
      throw Exception('La remise doit être entre 0 et 100%');
    }
    
    return copyWith(
      globalDiscount: discountPercentage,
      updatedAt: DateTime.now(),
    );
  }

  // Set tax rate
  Cart setTaxRate(double taxRate) {
    if (taxRate < 0 || taxRate > 100) {
      throw Exception('Le taux de taxe doit être entre 0 et 100%');
    }
    
    return copyWith(
      taxRate: taxRate,
      updatedAt: DateTime.now(),
    );
  }

  // Clear cart
  Cart clear() {
    return copyWith(
      items: [],
      globalDiscount: 0.0,
      updatedAt: DateTime.now(),
    );
  }

  // Get item by product id
  CartItem? getItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in cart
  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }

  @override
  List<Object?> get props => [
        id,
        items,
        globalDiscount,
        taxRate,
        createdAt,
        updatedAt,
        customerId,
        metadata,
      ];

  @override
  String toString() {
    return 'Cart(id: $id, items: ${items.length}, total: $total)';
  }
}