import 'package:equatable/equatable.dart';
import 'cart.dart';
import 'cart_item.dart';

enum InvoiceStatus {
  draft,
  pending,
  paid,
  cancelled,
  refunded,
}

enum PaymentMethod {
  cash,
  card,
  mobileMoney,
  bankTransfer,
  credit,
}

class Invoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final List<CartItem> items;
  final double subtotal;
  final double totalDiscount;
  final double taxAmount;
  final double total;
  final InvoiceStatus status;
  final PaymentMethod? paymentMethod;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.totalDiscount,
    required this.taxAmount,
    required this.total,
    this.status = InvoiceStatus.draft,
    this.paymentMethod,
    required this.createdAt,
    this.paidAt,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.notes,
    this.metadata,
  });

  // Factory constructor to create invoice from cart
  factory Invoice.fromCart({
    required String id,
    required String invoiceNumber,
    required Cart cart,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      items: cart.items,
      subtotal: cart.subtotal,
      totalDiscount: cart.totalDiscount,
      taxAmount: cart.taxAmount,
      total: cart.total,
      createdAt: DateTime.now(),
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      notes: notes,
      metadata: metadata,
    );
  }

  // Getters for calculated properties
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isPaid => status == InvoiceStatus.paid;
  bool get isPending => status == InvoiceStatus.pending;
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isCancelled => status == InvoiceStatus.cancelled;
  bool get isRefunded => status == InvoiceStatus.refunded;
  bool get hasCustomer => customerId != null || customerName != null;
  
  String get statusText {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Brouillon';
      case InvoiceStatus.pending:
        return 'En attente';
      case InvoiceStatus.paid:
        return 'Payée';
      case InvoiceStatus.cancelled:
        return 'Annulée';
      case InvoiceStatus.refunded:
        return 'Remboursée';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
      case PaymentMethod.credit:
        return 'Crédit';
      case null:
        return 'Non spécifié';
    }
  }

  // Copy with method for immutability
  Invoice copyWith({
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
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      items: items ?? this.items,
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

  // Mark as paid
  Invoice markAsPaid(PaymentMethod paymentMethod) {
    return copyWith(
      status: InvoiceStatus.paid,
      paymentMethod: paymentMethod,
      paidAt: DateTime.now(),
    );
  }

  // Mark as pending
  Invoice markAsPending() {
    return copyWith(
      status: InvoiceStatus.pending,
    );
  }

  // Cancel invoice
  Invoice cancel() {
    if (status == InvoiceStatus.paid) {
      throw Exception('Impossible d\'annuler une facture déjà payée');
    }
    return copyWith(
      status: InvoiceStatus.cancelled,
    );
  }

  // Refund invoice
  Invoice refund() {
    if (status != InvoiceStatus.paid) {
      throw Exception('Seules les factures payées peuvent être remboursées');
    }
    return copyWith(
      status: InvoiceStatus.refunded,
    );
  }

  // Update customer information
  Invoice updateCustomer({
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    return copyWith(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
  }

  // Add notes
  Invoice addNotes(String notes) {
    return copyWith(notes: notes);
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        items,
        subtotal,
        totalDiscount,
        taxAmount,
        total,
        status,
        paymentMethod,
        createdAt,
        paidAt,
        customerId,
        customerName,
        customerPhone,
        customerEmail,
        notes,
        metadata,
      ];

  @override
  String toString() {
    return 'Invoice(id: $id, number: $invoiceNumber, total: $total, status: $statusText)';
  }
}