// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      barcode: json['barcode'] as String,
      price: (json['price'] as num).toDouble(),
      costPrice: (json['costPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      minQuantity: (json['minQuantity'] as num).toInt(),
      category: json['category'] as String,
      unit: json['unit'] as String,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'barcode': instance.barcode,
      'price': instance.price,
      'costPrice': instance.costPrice,
      'quantity': instance.quantity,
      'minQuantity': instance.minQuantity,
      'category': instance.category,
      'unit': instance.unit,
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
    };
