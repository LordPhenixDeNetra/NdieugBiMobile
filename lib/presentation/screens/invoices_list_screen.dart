import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/invoice.dart';
import '../providers/invoice_provider.dart';
import '../../core/theme/app_colors.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  InvoiceStatus? _selectedStatus;
  bool _isSearching = false;
  List<Invoice> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final invoiceProvider = context.read<InvoiceProvider>();
    final results = await invoiceProvider.searchInvoices(query);
    
    setState(() {
      _searchResults = results;
    });
  }

  List<Invoice> _getFilteredInvoices() {
    final invoiceProvider = context.read<InvoiceProvider>();
    List<Invoice> invoices;

    if (_isSearching) {
      invoices = _searchResults;
    } else {
      invoices = invoiceProvider.invoices;
    }

    if (_selectedStatus != null) {
      invoices = invoices.where((invoice) => invoice.status == _selectedStatus).toList();
    }

    return invoices;
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
      case InvoiceStatus.refunded:
        return Colors.purple;
    }
  }

  String _getStatusText(InvoiceStatus status) {
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

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Toutes'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...InvoiceStatus.values.map((status) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getStatusText(status)),
              selected: _selectedStatus == status,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : null;
                });
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Facture #${invoice.invoiceNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(invoice.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (invoice.customerName != null)
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    invoice.customerName!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(invoice.createdAt),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${invoice.items.length} article${invoice.items.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${invoice.total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed('/invoice', arguments: invoice.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<InvoiceProvider>().loadInvoices(refresh: true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro, client...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // Status filters
          _buildStatusFilter(),
          
          const SizedBox(height: 16),
          
          // Invoices list
          Expanded(
            child: Consumer<InvoiceProvider>(
              builder: (context, invoiceProvider, child) {
                if (invoiceProvider.isLoading && invoiceProvider.invoices.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (invoiceProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${invoiceProvider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            invoiceProvider.loadInvoices(refresh: true);
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredInvoices = _getFilteredInvoices();

                if (filteredInvoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching 
                              ? 'Aucune facture trouvée pour "${_searchController.text}"'
                              : _selectedStatus != null
                                  ? 'Aucune facture ${_getStatusText(_selectedStatus!).toLowerCase()}'
                                  : 'Aucune facture disponible',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (!_isSearching && _selectedStatus == null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Les factures apparaîtront ici après vos premières ventes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => invoiceProvider.loadInvoices(refresh: true),
                  child: ListView.builder(
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return _buildInvoiceCard(invoice);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}