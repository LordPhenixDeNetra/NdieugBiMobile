// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceModel _$InvoiceModelFromJson(Map<String, dynamic> json) => InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      itemsJson: (json['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      totalDiscount: (json['totalDiscount'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: $enumDecodeNullable(_$InvoiceStatusEnumMap, json['status']) ??
          InvoiceStatus.draft,
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerEmail: json['customerEmail'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$InvoiceModelToJson(InvoiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceNumber': instance.invoiceNumber,
      'subtotal': instance.subtotal,
      'totalDiscount': instance.totalDiscount,
      'taxAmount': instance.taxAmount,
      'total': instance.total,
      'status': _$InvoiceStatusEnumMap[instance.status]!,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
      'createdAt': instance.createdAt.toIso8601String(),
      'paidAt': instance.paidAt?.toIso8601String(),
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'customerEmail': instance.customerEmail,
      'notes': instance.notes,
      'metadata': instance.metadata,
      'items': instance.itemsJson,
    };

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.draft: 'draft',
  InvoiceStatus.pending: 'pending',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.cancelled: 'cancelled',
  InvoiceStatus.refunded: 'refunded',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.card: 'card',
  PaymentMethod.mobileMoney: 'mobileMoney',
  PaymentMethod.bankTransfer: 'bankTransfer',
  PaymentMethod.credit: 'credit',
};
