import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.barcode,
    required super.price,
    required super.costPrice,
    required super.quantity,
    required super.minQuantity,
    required super.category,
    required super.unit,
    super.imageUrl,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.metadata,
  });

  // Factory constructor from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);

  // Method to convert to JSON
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  // Factory constructor from Entity
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      barcode: product.barcode,
      price: product.price,
      costPrice: product.costPrice,
      quantity: product.quantity,
      minQuantity: product.minQuantity,
      category: product.category,
      unit: product.unit,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      metadata: product.metadata,
    );
  }

  // Method to convert to Entity
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      barcode: barcode,
      price: price,
      costPrice: costPrice,
      quantity: quantity,
      minQuantity: minQuantity,
      category: category,
      unit: unit,
      imageUrl: imageUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  // Factory constructor from database map
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      barcode: map['barcode'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      minQuantity: map['min_quantity'] as int,
      category: map['category'] as String,
      unit: map['unit'] as String,
      imageUrl: map['image_url'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  // Method to convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'category': category,
      'unit': unit,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Copy with method that returns ProductModel
  @override
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? costPrice,
    int? quantity,
    int? minQuantity,
    String? category,
    String? unit,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}