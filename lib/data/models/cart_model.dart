import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_item_model.dart';

part 'cart_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartModel extends Cart {
  @JsonKey(name: 'items')
  final List<Map<String, dynamic>> itemsJson;

  const CartModel({
    required super.id,
    required this.itemsJson,
    super.globalDiscount = 0.0,
    super.taxRate = 0.0,
    required super.createdAt,
    required super.updatedAt,
    super.customerId,
    super.metadata,
  }) : super(items: const []);

  @override
  List<CartItem> get items => itemsJson
      .map((json) => CartItemModel.fromJson(json).toEntity())
      .toList();

  // Factory constructor from JSON
  factory CartModel.fromJson(Map<String, dynamic> json) => _$CartModelFromJson(json);

  // Method to convert to JSON
  Map<String, dynamic> toJson() => _$CartModelToJson(this);

  // Factory constructor from Entity
  factory CartModel.fromEntity(Cart cart) {
    return CartModel(
      id: cart.id,
      itemsJson: cart.items.map((item) => CartItemModel.fromEntity(item).toJson()).toList(),
      globalDiscount: cart.globalDiscount,
      taxRate: cart.taxRate,
      createdAt: cart.createdAt,
      updatedAt: cart.updatedAt,
      customerId: cart.customerId,
      metadata: cart.metadata,
    );
  }

  // Method to convert to Entity
  Cart toEntity() {
    return Cart(
      id: id,
      items: items,
      globalDiscount: globalDiscount,
      taxRate: taxRate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerId: customerId,
      metadata: metadata,
    );
  }

  // Factory constructor from database map
  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: map['id'] as String,
      itemsJson: [], // Items will be loaded separately
      globalDiscount: (map['global_discount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      customerId: map['customer_id'] as String?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  // Method to convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'global_discount': globalDiscount,
      'tax_rate': taxRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_id': customerId,
      'metadata': metadata,
    };
  }

  // Copy with method that returns CartModel
  @override
  CartModel copyWith({
    String? id,
    List<CartItem>? items,
    double? globalDiscount,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) {
    return CartModel(
      id: id ?? this.id,
      itemsJson: items != null 
          ? items.map((item) => CartItemModel.fromEntity(item).toJson()).toList()
          : itemsJson,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Method to copy with items
  CartModel copyWithItems(List<CartItemModel> items) {
    return CartModel(
      id: id,
      itemsJson: items.map((item) => item.toJson()).toList(),
      globalDiscount: globalDiscount,
      taxRate: taxRate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerId: customerId,
      metadata: metadata,
    );
  }
}