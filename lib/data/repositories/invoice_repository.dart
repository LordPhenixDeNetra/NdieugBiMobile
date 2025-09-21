import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../models/invoice_model.dart';
import '../models/cart_item_model.dart';
import '../../services/database_service.dart';

class InvoiceRepository {
  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  InvoiceRepository(this._databaseService);

  // Generate unique invoice number
  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp';
  }

  // Create invoice from cart
  Future<Invoice> createInvoiceFromCart({
    required Cart cart,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await _databaseService.database;
    
    final invoice = Invoice.fromCart(
      id: _uuid.v4(),
      invoiceNumber: _generateInvoiceNumber(),
      cart: cart,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      notes: notes,
      metadata: metadata,
    );

    await _saveInvoice(db, invoice);
    return invoice;
  }

  // Save invoice to database
  Future<void> _saveInvoice(Database db, Invoice invoice) async {
    await db.transaction((txn) async {
      // Insert invoice
      final invoiceModel = InvoiceModel.fromEntity(invoice);
      await txn.insert('invoices', invoiceModel.toMap());

      // Insert invoice items
      for (final item in invoice.items) {
        final itemModel = CartItemModel.fromEntity(item);
        await txn.insert('invoice_items', {
          'id': _uuid.v4(),
          'invoice_id': invoice.id,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'product_barcode': item.product.barcode,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
          'subtotal': item.subtotal,
          'total': item.total,
          'added_at': item.addedAt.toIso8601String(),
          'metadata': item.metadata != null ? itemModel.toJson()['metadata'] : null,
        });
      }
    });
  }

  // Get invoice by ID
  Future<Invoice?> getInvoiceById(String id) async {
    final db = await _databaseService.database;
    
    final invoiceResult = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (invoiceResult.isEmpty) return null;

    final itemsResult = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'added_at ASC',
    );

    final invoiceModel = InvoiceModel.fromMap(invoiceResult.first);
    final items = itemsResult.map((item) => CartItemModel.fromInvoiceItemMap(item).toEntity()).toList();
    
    return invoiceModel.copyWith(items: items).toEntity();
  }

  // Get invoice by number
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final db = await _databaseService.database;
    
    final invoiceResult = await db.query(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
    );

    if (invoiceResult.isEmpty) return null;

    final invoice = InvoiceModel.fromMap(invoiceResult.first);
    return getInvoiceById(invoice.id);
  }

  // Get all invoices with pagination
  Future<List<Invoice>> getInvoices({
    int limit = 50,
    int offset = 0,
    InvoiceStatus? status,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null) {
      whereClause += 'status = ?';
      whereArgs.add(status.toString().split('.').last);
    }

    if (customerId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'customer_id = ?';
      whereArgs.add(customerId);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final invoicesResult = await db.query(
      'invoices',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final invoices = <Invoice>[];
    for (final invoiceMap in invoicesResult) {
      final invoice = await getInvoiceById(invoiceMap['id'] as String);
      if (invoice != null) {
        invoices.add(invoice);
      }
    }

    return invoices;
  }

  // Update invoice status
  Future<Invoice> updateInvoiceStatus(String id, InvoiceStatus status, {PaymentMethod? paymentMethod}) async {
    final db = await _databaseService.database;
    
    final updateData = <String, dynamic>{
      'status': status.toString().split('.').last,
    };

    if (status == InvoiceStatus.paid) {
      updateData['paid_at'] = DateTime.now().toIso8601String();
      if (paymentMethod != null) {
        updateData['payment_method'] = paymentMethod.toString().split('.').last;
      }
    }

    await db.update(
      'invoices',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );

    final updatedInvoice = await getInvoiceById(id);
    if (updatedInvoice == null) {
      throw Exception('Facture non trouvée après mise à jour');
    }

    return updatedInvoice;
  }

  // Mark invoice as paid
  Future<Invoice> markInvoiceAsPaid(String id, PaymentMethod paymentMethod) async {
    return updateInvoiceStatus(id, InvoiceStatus.paid, paymentMethod: paymentMethod);
  }

  // Cancel invoice
  Future<Invoice> cancelInvoice(String id) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) {
      throw Exception('Facture non trouvée');
    }

    if (invoice.status == InvoiceStatus.paid) {
      throw Exception('Impossible d\'annuler une facture déjà payée');
    }

    return updateInvoiceStatus(id, InvoiceStatus.cancelled);
  }

  // Refund invoice
  Future<Invoice> refundInvoice(String id) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) {
      throw Exception('Facture non trouvée');
    }

    if (invoice.status != InvoiceStatus.paid) {
      throw Exception('Seules les factures payées peuvent être remboursées');
    }

    return updateInvoiceStatus(id, InvoiceStatus.refunded);
  }

  // Update customer information
  Future<Invoice> updateInvoiceCustomer(
    String id, {
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final db = await _databaseService.database;
    
    final updateData = <String, dynamic>{};
    if (customerId != null) updateData['customer_id'] = customerId;
    if (customerName != null) updateData['customer_name'] = customerName;
    if (customerPhone != null) updateData['customer_phone'] = customerPhone;
    if (customerEmail != null) updateData['customer_email'] = customerEmail;

    if (updateData.isNotEmpty) {
      await db.update(
        'invoices',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    final updatedInvoice = await getInvoiceById(id);
    if (updatedInvoice == null) {
      throw Exception('Facture non trouvée après mise à jour');
    }

    return updatedInvoice;
  }

  // Add notes to invoice
  Future<Invoice> addNotesToInvoice(String id, String notes) async {
    final db = await _databaseService.database;
    
    await db.update(
      'invoices',
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );

    final updatedInvoice = await getInvoiceById(id);
    if (updatedInvoice == null) {
      throw Exception('Facture non trouvée après mise à jour');
    }

    return updatedInvoice;
  }

  // Delete invoice (only if draft or cancelled)
  Future<void> deleteInvoice(String id) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) {
      throw Exception('Facture non trouvée');
    }

    if (invoice.status == InvoiceStatus.paid || invoice.status == InvoiceStatus.pending) {
      throw Exception('Impossible de supprimer une facture payée ou en attente');
    }

    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Get invoice statistics
  Future<Map<String, dynamic>> getInvoiceStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseService.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_invoices,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_invoices,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_invoices,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_invoices,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END), 0) as total_revenue,
        COALESCE(AVG(CASE WHEN status = 'paid' THEN total END), 0) as average_invoice_value
      FROM invoices
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
    ''', whereArgs);

    return result.first;
  }

  // Search invoices
  Future<List<Invoice>> searchInvoices(String query, {int limit = 20}) async {
    final db = await _databaseService.database;
    
    final invoicesResult = await db.query(
      'invoices',
      where: '''
        invoice_number LIKE ? OR 
        customer_name LIKE ? OR 
        customer_phone LIKE ? OR 
        customer_email LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    final invoices = <Invoice>[];
    for (final invoiceMap in invoicesResult) {
      final invoice = await getInvoiceById(invoiceMap['id'] as String);
      if (invoice != null) {
        invoices.add(invoice);
      }
    }

    return invoices;
  }
}