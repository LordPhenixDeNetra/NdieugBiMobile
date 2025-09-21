import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/invoice.dart';
import '../providers/invoice_provider.dart';
import '../../core/theme/app_colors.dart';

class InvoiceScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.invoice.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _markAsPaid() async {
    try {
      final invoiceProvider = context.read<InvoiceProvider>();
      await invoiceProvider.markInvoiceAsPaid(widget.invoice.id, PaymentMethod.cash);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facture marquée comme payée')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _printInvoice() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Simulate printing process
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facture envoyée à l\'imprimante')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Future<void> _updateNotes() async {
    try {
      final invoiceProvider = context.read<InvoiceProvider>();
      await invoiceProvider.updateInvoiceNotes(widget.invoice.id, _notesController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes mises à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _shareInvoice() {
    // Copy invoice details to clipboard
    final invoiceText = _generateInvoiceText();
    Clipboard.setData(ClipboardData(text: invoiceText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facture copiée dans le presse-papiers')),
    );
  }

  String _generateInvoiceText() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final buffer = StringBuffer();
    
    buffer.writeln('FACTURE #${widget.invoice.invoiceNumber}');
    buffer.writeln('Date: ${dateFormat.format(widget.invoice.createdAt)}');
    buffer.writeln('Statut: ${_getStatusText(widget.invoice.status)}');
    
    if (widget.invoice.customerName != null) {
      buffer.writeln('Client: ${widget.invoice.customerName}');
    }
    if (widget.invoice.customerPhone != null) {
      buffer.writeln('Téléphone: ${widget.invoice.customerPhone}');
    }
    
    buffer.writeln('\n--- ARTICLES ---');
    for (final item in widget.invoice.items) {
      buffer.writeln('${item.product.name} x${item.quantity}');
      buffer.writeln('  ${item.unitPrice.toStringAsFixed(0)} FCFA x ${item.quantity} = ${item.total.toStringAsFixed(0)} FCFA');
    }
    
    buffer.writeln('\n--- TOTAUX ---');
    buffer.writeln('Sous-total: ${widget.invoice.subtotal.toStringAsFixed(0)} FCFA');
    if (widget.invoice.totalDiscount > 0) {
      buffer.writeln('Remise: -${widget.invoice.totalDiscount.toStringAsFixed(0)} FCFA');
    }
    if (widget.invoice.taxAmount > 0) {
      buffer.writeln('Taxes: ${widget.invoice.taxAmount.toStringAsFixed(0)} FCFA');
    }
    buffer.writeln('TOTAL: ${widget.invoice.total.toStringAsFixed(0)} FCFA');
    
    if (widget.invoice.notes != null && widget.invoice.notes!.isNotEmpty) {
      buffer.writeln('\nNotes: ${widget.invoice.notes}');
    }
    
    return buffer.toString();
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
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Facture #${widget.invoice.invoiceNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInvoice,
          ),
          IconButton(
            icon: _isPrinting 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.print),
            onPressed: _isPrinting ? null : _printInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Facture #${widget.invoice.invoiceNumber}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${dateFormat.format(widget.invoice.createdAt)}',
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.invoice.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(widget.invoice.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (widget.invoice.customerName != null || widget.invoice.customerPhone != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const Text(
                        'Informations client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.invoice.customerName != null)
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.invoice.customerName!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      if (widget.invoice.customerPhone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.invoice.customerPhone!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Invoice items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Articles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.invoice.items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = widget.invoice.items[index];
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.product.barcode != null)
                                    Text(
                                      'Code: ${item.product.barcode}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.unitPrice.toStringAsFixed(0)} FCFA',
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.total.toStringAsFixed(0)} FCFA',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Invoice totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sous-total:', style: TextStyle(fontSize: 16)),
                        Text(
                          '${widget.invoice.subtotal.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    if (widget.invoice.totalDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Remise:',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                          Text(
                            '-${widget.invoice.totalDiscount.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    if (widget.invoice.taxAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Taxes:', style: TextStyle(fontSize: 16)),
                          Text(
                            '${widget.invoice.taxAmount.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.invoice.total.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter des notes...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        // Auto-save notes after a delay
                        Future.delayed(const Duration(seconds: 2), () {
                          if (_notesController.text == value) {
                            _updateNotes();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (widget.invoice.status == InvoiceStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markAsPaid,
                  icon: const Icon(Icons.payment),
                  label: const Text('Marquer comme payée'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting ? null : _printInvoice,
                    icon: _isPrinting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                    label: Text(_isPrinting ? 'Impression...' : 'Imprimer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareInvoice,
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}