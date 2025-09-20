import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import 'product_model.dart';

part 'cart_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItemModel {
  final String id;
  @JsonKey(name: 'product')
  final Map<String, dynamic> productJson;
  final int quantity;
  final double unitPrice;
  final double discount;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;

  const CartItemModel({
    required this.id,
    required this.productJson,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.addedAt,
    this.metadata,
  });

  Product get product => ProductModel.fromJson(productJson);

  // Getters for calculated properties (from CartItem)
  String get productId => product.id;
  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;
  bool get hasDiscount => discount > 0;

  // Factory constructor from JSON
  factory CartItemModel.fromJson(Map<String, dynamic> json) => _$CartItemModelFromJson(json);

  // Method to convert to JSON
  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  // Factory constructor from Entity
  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      id: cartItem.id,
      productJson: ProductModel.fromEntity(cartItem.product).toJson(),
      quantity: cartItem.quantity,
      unitPrice: cartItem.unitPrice,
      discount: cartItem.discount,
      addedAt: cartItem.addedAt,
      metadata: cartItem.metadata,
    );
  }

  // Method to convert to Entity
  CartItem toEntity() {
    return CartItem(
      id: id,
      product: (product as ProductModel).toEntity(),
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      addedAt: addedAt,
      metadata: metadata,
    );
  }

  // Factory constructor from database map
  factory CartItemModel.fromMap(Map<String, dynamic> map, Product product) {
    return CartItemModel(
      id: map['id'] as String,
      productJson: ProductModel.fromEntity(product).toJson(),
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      addedAt: DateTime.parse(map['added_at'] as String),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  // Method to convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cart_id': null, // Will be set when saving to database
      'product_id': product.id,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'added_at': addedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Method to convert to database map with cart ID
  Map<String, dynamic> toMapWithCartId(String cartId) {
    final map = toMap();
    map['cart_id'] = cartId;
    return map;
  }

  // Copy with method that returns CartItemModel
  CartItemModel copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discount,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productJson: product != null ? ProductModel.fromEntity(product).toJson() : productJson,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}