import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import 'barcode_scanner_widget.dart';

class EditProductForm extends StatefulWidget {
  final Product product;
  
  const EditProductForm({
    super.key,
    required this.product,
  });

  @override
  State<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _categoryController;
  late final TextEditingController _unitController;

  bool _isLoading = false;

  // Predefined categories and units for dropdowns
  final List<String> _categories = [
    'Alimentation',
    'Boissons',
    'Hygiène',
    'Électronique',
    'Vêtements',
    'Maison',
    'Sport',
    'Autre'
  ];

  final List<String> _units = [
    'pièce',
    'kg',
    'g',
    'litre',
    'ml',
    'mètre',
    'cm',
    'paquet',
    'boîte',
    'carton'
  ];

  String? _selectedCategory;
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _barcodeController = TextEditingController(text: widget.product.barcode);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _costPriceController = TextEditingController(text: widget.product.costPrice.toStringAsFixed(0));
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _minQuantityController = TextEditingController(text: widget.product.minQuantity.toString());
    _categoryController = TextEditingController(text: widget.product.category);
    _unitController = TextEditingController(text: widget.product.unit);
    
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modifier le produit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nom du produit
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'Nom du produit',
                        icon: Icons.inventory_2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom du produit est requis';
                          }
                          if (value.trim().length < 2) {
                            return 'Le nom doit contenir au moins 2 caractères';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      _buildTextFormField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La description est requise';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Code-barres avec scanner
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _barcodeController,
                              label: 'Code-barres',
                              icon: Icons.qr_code,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le code-barres est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _scanBarcode,
                              icon: Icon(
                                Icons.qr_code_scanner,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              tooltip: 'Scanner le code-barres',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Prix et Prix de revient (côte à côte)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _priceController,
                              label: 'Prix de vente (FCFA)',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le prix de vente est requis';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Prix invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _costPriceController,
                              label: 'Prix de revient (FCFA)',
                              icon: Icons.money_off,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le prix de revient est requis';
                                }
                                final costPrice = double.tryParse(value);
                                if (costPrice == null || costPrice < 0) {
                                  return 'Prix invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quantité et Quantité minimale (côte à côte)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _quantityController,
                              label: 'Quantité en stock',
                              icon: Icons.inventory,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'La quantité est requise';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity < 0) {
                                  return 'Quantité invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _minQuantityController,
                              label: 'Quantité minimale',
                              icon: Icons.warning,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'La quantité minimale est requise';
                                }
                                final minQuantity = int.tryParse(value);
                                if (minQuantity == null || minQuantity < 0) {
                                  return 'Quantité invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Catégorie et Unité (côte à côte)
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDropdownField(
                              value: _selectedCategory,
                              label: 'Catégorie',
                              icon: Icons.category,
                              items: _categories,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _categoryController.text = value ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La catégorie est requise';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: _buildDropdownField(
                              value: _selectedUnit,
                              label: 'Unité',
                              icon: Icons.straighten,
                              items: _units,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value;
                                  _unitController.text = value ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'L\'unité est requise';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: theme.colorScheme.outline),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProduct,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Modifier'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        barcode: _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costPriceController.text),
        quantity: int.parse(_quantityController.text),
        minQuantity: int.parse(_minQuantityController.text),
        category: _selectedCategory!,
        unit: _selectedUnit!,
        updatedAt: DateTime.now(),
      );

      await context.read<ProductProvider>().updateProduct(updatedProduct);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit "${updatedProduct.name}" modifié avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification du produit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => BarcodeScannerWidget(
          onBarcodeScanned: (barcode) {
            _barcodeController.text = barcode;
            Navigator.of(context).pop();
          },
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _barcodeController.text = result;
        });
        
        // Vérifier si un autre produit utilise déjà ce code-barres
        await _checkExistingProduct(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du scan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _checkExistingProduct(String barcode) async {
    try {
      final productProvider = context.read<ProductProvider>();
      final existingProduct = productProvider.getProductByBarcode(barcode);

      if (existingProduct != null && existingProduct.id != widget.product.id && mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Produit existant'),
            content: Text(
              'Un autre produit avec ce code-barres existe déjà:\n\n'
              'Nom: ${existingProduct.name}\n'
              'Prix: ${existingProduct.price.toStringAsFixed(0)} FCFA\n\n'
              'Voulez-vous continuer avec ce code-barres ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuer'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          setState(() {
            _barcodeController.text = widget.product.barcode;
          });
        }
      }
    } catch (e) {
      // Erreur silencieuse pour ne pas interrompre le processus
      debugPrint('Erreur lors de la vérification du produit existant: $e');
    }
  }
}