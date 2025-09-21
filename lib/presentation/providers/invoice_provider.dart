import 'package:flutter/foundation.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/cart.dart';
import '../../data/repositories/invoice_repository.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceRepository _invoiceRepository;

  InvoiceProvider(this._invoiceRepository);

  // Current state
  List<Invoice> _invoices = [];
  Invoice? _currentInvoice;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  // Getters
  List<Invoice> get invoices => _invoices;
  Invoice? get currentInvoice => _currentInvoice;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Filtered invoices
  List<Invoice> get paidInvoices => _invoices.where((invoice) => invoice.isPaid).toList();
  List<Invoice> get pendingInvoices => _invoices.where((invoice) => invoice.isPending).toList();
  List<Invoice> get draftInvoices => _invoices.where((invoice) => invoice.isDraft).toList();
  List<Invoice> get cancelledInvoices => _invoices.where((invoice) => invoice.isCancelled).toList();

  // Statistics getters
  double get totalRevenue => _statistics?['total_revenue']?.toDouble() ?? 0.0;
  int get totalInvoices => _statistics?['total_invoices'] ?? 0;
  int get totalPaidInvoices => _statistics?['paid_invoices'] ?? 0;
  int get totalPendingInvoices => _statistics?['pending_invoices'] ?? 0;
  double get averageInvoiceValue => _statistics?['average_invoice_value']?.toDouble() ?? 0.0;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Create invoice from cart
  Future<Invoice?> createInvoiceFromCart({
    required Cart cart,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final invoice = await _invoiceRepository.createInvoiceFromCart(
        cart: cart,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        notes: notes,
        metadata: metadata,
      );

      _currentInvoice = invoice;
      _invoices.insert(0, invoice); // Add to beginning of list
      
      notifyListeners();
      return invoice;
    } catch (e) {
      _setError('Erreur lors de la création de la facture: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Load invoice by ID
  Future<Invoice?> loadInvoiceById(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final invoice = await _invoiceRepository.getInvoiceById(id);
      _currentInvoice = invoice;
      
      notifyListeners();
      return invoice;
    } catch (e) {
      _setError('Erreur lors du chargement de la facture: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Load invoice by number
  Future<Invoice?> loadInvoiceByNumber(String invoiceNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      final invoice = await _invoiceRepository.getInvoiceByNumber(invoiceNumber);
      _currentInvoice = invoice;
      
      notifyListeners();
      return invoice;
    } catch (e) {
      _setError('Erreur lors du chargement de la facture: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Load all invoices
  Future<void> loadInvoices({
    int limit = 50,
    int offset = 0,
    InvoiceStatus? status,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final invoices = await _invoiceRepository.getInvoices(
        limit: limit,
        offset: offset,
        status: status,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );

      if (refresh || offset == 0) {
        _invoices = invoices;
      } else {
        _invoices.addAll(invoices);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des factures: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Search invoices
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      _setError(null);
      return await _invoiceRepository.searchInvoices(query);
    } catch (e) {
      _setError('Erreur lors de la recherche: ${e.toString()}');
      return [];
    }
  }

  // Mark invoice as paid
  Future<bool> markInvoiceAsPaid(String id, PaymentMethod paymentMethod) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedInvoice = await _invoiceRepository.markInvoiceAsPaid(id, paymentMethod);
      
      // Update in current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }

      // Update in invoices list
      final index = _invoices.indexWhere((invoice) => invoice.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors du paiement de la facture: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel invoice
  Future<bool> cancelInvoice(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedInvoice = await _invoiceRepository.cancelInvoice(id);
      
      // Update in current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }

      // Update in invoices list
      final index = _invoices.indexWhere((invoice) => invoice.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'annulation de la facture: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refund invoice
  Future<bool> refundInvoice(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedInvoice = await _invoiceRepository.refundInvoice(id);
      
      // Update in current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }

      // Update in invoices list
      final index = _invoices.indexWhere((invoice) => invoice.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors du remboursement de la facture: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update customer information
  Future<bool> updateInvoiceCustomer(
    String id, {
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedInvoice = await _invoiceRepository.updateInvoiceCustomer(
        id,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );
      
      // Update in current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }

      // Update in invoices list
      final index = _invoices.indexWhere((invoice) => invoice.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour du client: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update invoice notes
  Future<bool> updateInvoiceNotes(String id, String notes) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedInvoice = await _invoiceRepository.addNotesToInvoice(id, notes);
      
      // Update in current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }

      // Update in invoices list
      final index = _invoices.indexWhere((invoice) => invoice.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour des notes: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add notes to invoice
  Future<bool> addNotesToInvoice(String id, String notes) async {
    try {
      _setLoading(true);
      _setError(null);

      final updatedInvoice = await _invoiceRepository.addNotesToInvoice(id, notes);
      
      // Update in current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }

      // Update in invoices list
      final index = _invoices.indexWhere((invoice) => invoice.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de notes: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete invoice
  Future<bool> deleteInvoice(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      await _invoiceRepository.deleteInvoice(id);
      
      // Remove from current invoice if it's the same
      if (_currentInvoice?.id == id) {
        _currentInvoice = null;
      }

      // Remove from invoices list
      _invoices.removeWhere((invoice) => invoice.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de la facture: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setError(null);

      _statistics = await _invoiceRepository.getInvoiceStatistics(
        startDate: startDate,
        endDate: endDate,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des statistiques: ${e.toString()}');
    }
  }

  // Set current invoice
  void setCurrentInvoice(Invoice? invoice) {
    _currentInvoice = invoice;
    notifyListeners();
  }

  // Clear current invoice
  void clearCurrentInvoice() {
    _currentInvoice = null;
    notifyListeners();
  }

  // Refresh invoices
  Future<void> refreshInvoices() async {
    await loadInvoices(refresh: true);
  }

  // Get invoice by ID from current list
  Invoice? getInvoiceFromList(String id) {
    try {
      return _invoices.firstWhere((invoice) => invoice.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter invoices by status
  List<Invoice> getInvoicesByStatus(InvoiceStatus status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  // Filter invoices by date range
  List<Invoice> getInvoicesByDateRange(DateTime startDate, DateTime endDate) {
    return _invoices.where((invoice) {
      return invoice.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
             invoice.createdAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get invoices for customer
  List<Invoice> getInvoicesForCustomer(String customerId) {
    return _invoices.where((invoice) => invoice.customerId == customerId).toList();
  }
}