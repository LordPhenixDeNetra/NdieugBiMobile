import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';

/// JsonConverter for Product entities
class ProductConverter implements JsonConverter<Product, Map<String, dynamic>> {
  const ProductConverter();

  @override
  Product fromJson(Map<String, dynamic> json) {
    return ProductModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Product object) {
    return ProductModel.fromEntity(object).toJson();
  }
}

/// JsonConverter for CartItem entities
class CartItemConverter implements JsonConverter<CartItem, Map<String, dynamic>> {
  const CartItemConverter();

  @override
  CartItem fromJson(Map<String, dynamic> json) {
    return CartItemModel.fromJson(json).toEntity();
  }

  @override
  Map<String, dynamic> toJson(CartItem object) {
    return CartItemModel.fromEntity(object).toJson();
  }
}

/// JsonConverter for List of CartItem entities
class CartItemListConverter implements JsonConverter<List<CartItem>, List<dynamic>> {
  const CartItemListConverter();

  @override
  List<CartItem> fromJson(List<dynamic> json) {
    return json.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>).toEntity()).toList();
  }

  @override
  List<dynamic> toJson(List<CartItem> object) {
    return object.map((item) => CartItemModel.fromEntity(item).toJson()).toList();
  }
}