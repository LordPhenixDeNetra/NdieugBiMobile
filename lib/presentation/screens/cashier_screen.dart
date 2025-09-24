import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/invoice.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/cart_item_card.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _showScanner = false;
  List<Product> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadActiveCart();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _showScanner = true;
      _isScanning = true;
    });
    
    _scannerController = MobileScannerController();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() {
          _barcodeController.text = code;
          _showScanner = false;
          _isScanning = false;
        });
        _scannerController?.dispose();
        _scannerController = null;
        _searchProduct(code);
      }
    }
  }

  void _searchProduct(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final productProvider = context.read<ProductProvider>();
    productProvider.searchProducts(query);
    final results = productProvider.products;
    
    setState(() {
      _searchResults = results;
    });

    if (results.isNotEmpty && results.length == 1) {
      _addToCart(results.first);
    }
  }

  void _addToCart(Product product) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantité invalide')),
      );
      return;
    }

    // Vérifier si le produit est en rupture de stock
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} est en rupture de stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (quantity > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock insuffisant (${product.stock} disponible)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<CartProvider>().addProduct(product, quantity: quantity);
    
    setState(() {
      _barcodeController.clear();
      _quantityController.text = '1';
      _searchResults = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} ajouté au panier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.point_of_sale, color: Colors.amber),
                SizedBox(width: 8),
                Text('Caisse', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  final itemCount = cartProvider.itemCount;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: () {
                          // Navigate to cart summary or checkout
                        },
                      ),
                      if (itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: _showScanner ? _buildScanner() : _buildMainContent(isDarkMode),
        );
      },
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onBarcodeDetected,
        ),
        Positioned(
          top: 50,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.red,
            onPressed: () {
              setState(() {
                _showScanner = false;
                _isScanning = false;
              });
              _scannerController?.dispose();
              _scannerController = null;
            },
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    return Column(
      children: [
        // Input section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Code-barres',
                        prefixIcon: const Icon(Icons.qr_code_scanner),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[50],
                      ),
                      onChanged: _searchProduct,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Qté',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scanner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_searchResults.isNotEmpty) {
                          _addToCart(_searchResults.first);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search results
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résultats de recherche:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ..._searchResults.take(3).map((product) => Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: ListTile(
                    title: Text(
                      product.name,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${product.price.toStringAsFixed(0)} FCFA - Stock: ${product.stock}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => _addToCart(product),
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Cart section
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cart header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Articles du panier',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final itemCount = cartProvider.itemCount;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$itemCount articles',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Cart items
                Expanded(
                  child: Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      if (cartProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (cartProvider.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Panier vide',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scannez un produit pour commencer',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartProvider.currentCart!.items.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final item = cartProvider.currentCart!.items[index];
                          return CartItemCard(
                            item: item,
                            product: item.product,
                            onQuantityChanged: (newQuantity) {
                              if (newQuantity <= 0) {
                                cartProvider.removeProduct(item.productId);
                              } else {
                                cartProvider.updateQuantity(item.productId, newQuantity);
                              }
                            },
                            onDiscountChanged: (discount) {
                              cartProvider.updateItemDiscount(item.productId, discount);
                            },
                            onRemove: () {
                              cartProvider.removeProduct(item.productId);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Order summary
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isEmpty) return const SizedBox.shrink();
            
            final cart = cartProvider.currentCart!;
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.receipt_long, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Résumé de la commande',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Articles', '${cart.items.length}', isDarkMode),
                  _buildSummaryRow('Sous-total', '${cart.subtotal.toStringAsFixed(0)} FCFA', isDarkMode),
                  const Divider(),
                  _buildSummaryRow('TOTAL', '${cart.total.toStringAsFixed(0)} FCFA', isDarkMode, isTotal: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _processPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Procéder au paiement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDarkMode, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    try {
      final cartProvider = context.read<CartProvider>();
      final invoiceProvider = context.read<InvoiceProvider>();
      
      // Vérifier si le panier n'est pas vide
      if (cartProvider.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le panier est vide'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Créer la facture à partir du panier
      final invoice = await invoiceProvider.createInvoiceFromCart(
        cart: cartProvider.currentCart!,
      );

      if (invoice != null) {
        // Marquer la facture comme payée (paiement en espèces par défaut)
        await invoiceProvider.markInvoiceAsPaid(invoice.id, PaymentMethod.cash);
        
        // Vider le panier après le paiement
        await cartProvider.clearCart();
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement effectué avec succès! Facture: ${invoice.invoiceNumber}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // Naviguer vers l'écran de facture
                Navigator.of(context).pushNamed('/invoice', arguments: invoice.id);
              },
            ),
          ),
        );
      } else {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: ${invoiceProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs inattendues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}