import 'product.dart';
import 'cart.dart';

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int productId;
  final Product? product;
  final int quantity;
  final double unitPrice;
  final double? discount;
  final double? taxRate;
  final String? description;

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    this.taxRate,
    this.description,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount => discount ?? 0;
  double get taxAmount => ((subtotal - discountAmount) * (taxRate ?? 0)) / 100;
  double get total => subtotal - discountAmount + taxAmount;

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: map['discount'] != null ? (map['discount'] as num).toDouble() : null,
      taxRate: map['tax_rate'] != null ? (map['tax_rate'] as num).toDouble() : null,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax_rate': taxRate,
      'description': description,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product': product?.toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax_rate': taxRate,
      'description': description,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total': total,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int?,
      invoiceId: json['invoice_id'] as int,
      productId: json['product_id'] as int,
      product: json['product'] != null 
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
      taxRate: json['tax_rate'] != null ? (json['tax_rate'] as num).toDouble() : null,
      description: json['description'] as String?,
    );
  }

  factory InvoiceItem.fromCartItem(CartItem cartItem, int invoiceId) {
    return InvoiceItem(
      invoiceId: invoiceId,
      productId: cartItem.productId,
      product: cartItem.product,
      quantity: cartItem.quantity,
      unitPrice: cartItem.unitPrice,
      discount: cartItem.discount,
      description: cartItem.notes,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? taxRate,
    String? description,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'InvoiceItem{id: $id, productId: $productId, quantity: $quantity, total: $total}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItem &&
        other.id == id &&
        other.invoiceId == invoiceId &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ invoiceId.hashCode ^ productId.hashCode;
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final List<InvoiceItem> items;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final String? notes;
  final double? taxRate;
  final double? shippingCost;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    this.items = const [],
    DateTime? invoiceDate,
    this.dueDate,
    this.status = 'draft',
    this.notes,
    this.taxRate,
    this.shippingCost,
    this.paymentMethod,
    this.paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : invoiceDate = invoiceDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculs de la facture
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get totalTax => items.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal - totalDiscount + totalTax + (shippingCost ?? 0);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isPaid => status == 'paid';
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      customerEmail: map['customer_email'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerAddress: map['customer_address'] as String?,
      invoiceDate: map['invoice_date'] != null 
          ? DateTime.parse(map['invoice_date'] as String)
          : DateTime.now(),
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date'] as String)
          : null,
      status: map['status'] as String? ?? 'draft',
      notes: map['notes'] as String?,
      taxRate: map['tax_rate'] != null ? (map['tax_rate'] as num).toDouble() : null,
      shippingCost: map['shipping_cost'] != null ? (map['shipping_cost'] as num).toDouble() : null,
      paymentMethod: map['payment_method'] as String?,
      paidAt: map['paid_at'] != null 
          ? DateTime.parse(map['paid_at'] as String)
          : null,
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
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'tax_rate': taxRate,
      'shipping_cost': shippingCost,
      'payment_method': paymentMethod,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'tax_rate': taxRate,
      'shipping_cost': shippingCost,
      'payment_method': paymentMethod,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'total_tax': totalTax,
      'total': total,
      'item_count': itemCount,
      'is_paid': isPaid,
      'is_overdue': isOverdue,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int?,
      invoiceNumber: json['invoice_number'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerAddress: json['customer_address'] as String?,
      items: json['items'] != null 
          ? (json['items'] as List).map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>)).toList()
          : [],
      invoiceDate: json['invoice_date'] != null 
          ? DateTime.parse(json['invoice_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      taxRate: json['tax_rate'] != null ? (json['tax_rate'] as num).toDouble() : null,
      shippingCost: json['shipping_cost'] != null ? (json['shipping_cost'] as num).toDouble() : null,
      paymentMethod: json['payment_method'] as String?,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  factory Invoice.fromCart(Cart cart, String invoiceNumber) {
    return Invoice(
      invoiceNumber: invoiceNumber,
      customerId: cart.customerId,
      items: cart.items.map((cartItem) => InvoiceItem.fromCartItem(cartItem, 0)).toList(),
      notes: cart.notes,
      invoiceDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    List<InvoiceItem>? items,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? status,
    String? notes,
    double? taxRate,
    double? shippingCost,
    String? paymentMethod,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      taxRate: taxRate ?? this.taxRate,
      shippingCost: shippingCost ?? this.shippingCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Invoice{id: $id, number: $invoiceNumber, total: $total, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice &&
        other.id == id &&
        other.invoiceNumber == invoiceNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^ invoiceNumber.hashCode;
  }
}