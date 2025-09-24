import 'product.dart';

class CartItem {
  final int? id;
  final int productId;
  final Product? product;
  final int quantity;
  final double unitPrice;
  final double? discount;
  final String? notes;
  final DateTime addedAt;

  CartItem({
    this.id,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    this.notes,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  double get totalPrice => (unitPrice * quantity) - (discount ?? 0);
  double get discountAmount => discount ?? 0;
  double get subtotal => unitPrice * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: map['discount'] != null ? (map['discount'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      addedAt: map['added_at'] != null 
          ? DateTime.parse(map['added_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'notes': notes,
      'added_at': addedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product': product?.toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'notes': notes,
      'added_at': addedAt.toIso8601String(),
      'total_price': totalPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      product: json['product'] != null 
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      addedAt: json['added_at'] != null 
          ? DateTime.parse(json['added_at'] as String)
          : DateTime.now(),
    );
  }

  CartItem copyWith({
    int? id,
    int? productId,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discount,
    String? notes,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'CartItem{id: $id, productId: $productId, quantity: $quantity, totalPrice: $totalPrice}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.productId == productId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return id.hashCode ^ productId.hashCode ^ quantity.hashCode;
  }
}

class Cart {
  final int? id;
  final String? customerId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'active', 'completed', 'abandoned'
  final String? notes;

  Cart({
    this.id,
    this.customerId,
    this.items = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = 'active',
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculs du panier
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      id: map['id'] as int?,
      customerId: map['customer_id'] as String?,
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'total': total,
      'item_count': itemCount,
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as int?,
      customerId: json['customer_id'] as String?,
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList()
          : [],
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Cart copyWith({
    int? id,
    String? customerId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? notes,
  }) {
    return Cart(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  // Méthodes utilitaires
  Cart addItem(CartItem item) {
    final existingIndex = items.indexWhere((i) => i.productId == item.productId);
    
    if (existingIndex >= 0) {
      // Mettre à jour la quantité si le produit existe déjà
      final updatedItems = List<CartItem>.from(items);
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
      return copyWith(items: updatedItems, updatedAt: DateTime.now());
    } else {
      // Ajouter un nouvel item
      return copyWith(
        items: [...items, item],
        updatedAt: DateTime.now(),
      );
    }
  }

  Cart removeItem(int productId) {
    return copyWith(
      items: items.where((item) => item.productId != productId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  Cart updateItemQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return copyWith(items: updatedItems, updatedAt: DateTime.now());
  }

  Cart clear() {
    return copyWith(items: [], updatedAt: DateTime.now());
  }

  @override
  String toString() {
    return 'Cart{id: $id, itemCount: $itemCount, total: $total, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart &&
        other.id == id &&
        other.customerId == customerId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^ customerId.hashCode ^ status.hashCode;
  }
}