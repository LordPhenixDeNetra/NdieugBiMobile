import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_item_model.dart';

part 'invoice_model.g.dart';

@JsonSerializable(explicitToJson: true)
class InvoiceModel extends Invoice {
  @JsonKey(name: 'items')
  final List<Map<String, dynamic>> itemsJson;

  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required this.itemsJson,
    required super.subtotal,
    required super.totalDiscount,
    required super.taxAmount,
    required super.total,
    super.status = InvoiceStatus.draft,
    super.paymentMethod,
    required super.createdAt,
    super.paidAt,
    super.customerId,
    super.customerName,
    super.customerPhone,
    super.customerEmail,
    super.notes,
    super.metadata,
  }) : super(items: const []);

  @override
  List<CartItem> get items => itemsJson
      .map((json) => CartItemModel.fromJson(json).toEntity())
      .toList();

  // Factory constructor from JSON
  factory InvoiceModel.fromJson(Map<String, dynamic> json) => _$InvoiceModelFromJson(json);

  // Method to convert to JSON
  Map<String, dynamic> toJson() => _$InvoiceModelToJson(this);

  // Factory constructor from Entity
  factory InvoiceModel.fromEntity(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      itemsJson: invoice.items.map((item) => CartItemModel.fromEntity(item).toJson()).toList(),
      subtotal: invoice.subtotal,
      totalDiscount: invoice.totalDiscount,
      taxAmount: invoice.taxAmount,
      total: invoice.total,
      status: invoice.status,
      paymentMethod: invoice.paymentMethod,
      createdAt: invoice.createdAt,
      paidAt: invoice.paidAt,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      customerPhone: invoice.customerPhone,
      customerEmail: invoice.customerEmail,
      notes: invoice.notes,
      metadata: invoice.metadata,
    );
  }

  // Method to convert to Entity
  Invoice toEntity() {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      items: items,
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      taxAmount: taxAmount,
      total: total,
      status: status,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      paidAt: paidAt,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      notes: notes,
      metadata: metadata,
    );
  }

  // Factory constructor from database map
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      itemsJson: [], // Items will be loaded separately
      subtotal: (map['subtotal'] as num).toDouble(),
      totalDiscount: (map['total_discount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == map['payment_method'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      paidAt: map['paid_at'] != null 
          ? DateTime.parse(map['paid_at'] as String) 
          : null,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerEmail: map['customer_email'] as String?,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  // Method to convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'tax_amount': taxAmount,
      'total': total,
      'status': status.toString().split('.').last,
      'payment_method': paymentMethod?.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'notes': notes,
      'metadata': metadata,
    };
  }

  // Copy with method that returns InvoiceModel
  @override
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    List<CartItem>? items,
    double? subtotal,
    double? totalDiscount,
    double? taxAmount,
    double? total,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? paidAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      itemsJson: items?.map((item) => CartItemModel.fromEntity(item).toJson()).toList() ?? itemsJson,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Method to copy with items
  InvoiceModel copyWithItems(List<CartItemModel> items) {
    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      itemsJson: items.map((item) => item.toJson()).toList(),
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      taxAmount: taxAmount,
      total: total,
      status: status,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      paidAt: paidAt,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      notes: notes,
      metadata: metadata,
    );
  }
}