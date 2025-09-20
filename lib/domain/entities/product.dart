import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final String barcode;
  final double price;
  final double costPrice;
  final int quantity;
  final int minQuantity;
  final String category;
  final String unit;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.barcode,
    required this.price,
    required this.costPrice,
    required this.quantity,
    required this.minQuantity,
    required this.category,
    required this.unit,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // Getters for calculated properties
  double get profit => price - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
  bool get isLowStock => quantity <= minQuantity;
  double get totalValue => quantity * costPrice;
  
  // Alias getters for compatibility
  int get stock => quantity;
  int get minStock => minQuantity;

  // Copy with method for immutability
  Product copyWith({
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
    return Product(
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

  // Update quantity method
  Product updateQuantity(int newQuantity) {
    return copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    );
  }

  // Reduce quantity method (for sales)
  Product reduceQuantity(int amount) {
    final newQuantity = quantity - amount;
    if (newQuantity < 0) {
      throw Exception('Quantité insuffisante en stock');
    }
    return updateQuantity(newQuantity);
  }

  // Add quantity method (for restocking)
  Product addQuantity(int amount) {
    return updateQuantity(quantity + amount);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        barcode,
        price,
        costPrice,
        quantity,
        minQuantity,
        category,
        unit,
        imageUrl,
        isActive,
        createdAt,
        updatedAt,
        metadata,
      ];

  @override
  String toString() {
    return 'Product(id: $id, name: $name, barcode: $barcode, price: $price, quantity: $quantity)';
  }
}