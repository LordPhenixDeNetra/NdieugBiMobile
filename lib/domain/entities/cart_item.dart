import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double discount;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.addedAt,
    this.metadata,
  });

  // Getters for calculated properties
  String get productId => product.id;
  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;
  bool get hasDiscount => discount > 0;

  // Copy with method for immutability
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discount,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Update quantity method
  CartItem updateQuantity(int newQuantity) {
    if (newQuantity <= 0) {
      throw Exception('La quantité doit être supérieure à zéro');
    }
    if (newQuantity > product.quantity) {
      throw Exception('Quantité demandée supérieure au stock disponible');
    }
    return copyWith(quantity: newQuantity);
  }

  // Apply discount method
  CartItem applyDiscount(double discountPercentage) {
    if (discountPercentage < 0 || discountPercentage > 100) {
      throw Exception('La remise doit être entre 0 et 100%');
    }
    return copyWith(discount: discountPercentage);
  }

  // Increment quantity method
  CartItem incrementQuantity() {
    return updateQuantity(quantity + 1);
  }

  // Decrement quantity method
  CartItem decrementQuantity() {
    if (quantity <= 1) {
      throw Exception('La quantité ne peut pas être inférieure à 1');
    }
    return updateQuantity(quantity - 1);
  }

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        unitPrice,
        discount,
        addedAt,
        metadata,
      ];

  @override
  String toString() {
    return 'CartItem(id: $id, product: ${product.name}, quantity: $quantity, total: $total)';
  }
}