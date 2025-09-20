import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import 'barcode_scanner_widget.dart';

class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    Icons.add_box,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nouveau Produit',
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
                      
                      // Code-barres avec bouton de scan
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _barcodeController,
                              label: 'Code-barres',
                              icon: Icons.qr_code,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le code-barres est requis';
                                }
                                if (value.trim().length < 8) {
                                  return 'Le code-barres doit contenir au moins 8 chiffres';
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
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le prix est requis';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Prix invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _costPriceController,
                              label: 'Prix de revient (FCFA)',
                              icon: Icons.money_off,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le prix de revient est requis';
                                }
                                final costPrice = double.tryParse(value);
                                if (costPrice == null || costPrice < 0) {
                                  return 'Prix de revient invalide';
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
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _minQuantityController,
                              label: 'Stock minimum',
                              icon: Icons.warning,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le stock minimum est requis';
                                }
                                final minQuantity = int.tryParse(value);
                                if (minQuantity == null || minQuantity < 0) {
                                  return 'Stock minimum invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Catégorie
                      _buildDropdownField(
                        value: _selectedCategory,
                        label: 'Catégorie',
                        icon: Icons.category,
                        items: _categories,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La catégorie est requise';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Unité
                      _buildDropdownField(
                        value: _selectedUnit,
                        label: 'Unité',
                        icon: Icons.straighten,
                        items: _units,
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'unité est requise';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final product = Product(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        barcode: _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costPriceController.text),
        quantity: int.parse(_quantityController.text),
        minQuantity: int.parse(_minQuantityController.text),
        category: _selectedCategory!,
        unit: _selectedUnit!,
        createdAt: now,
        updatedAt: now,
      );

      await context.read<ProductProvider>().createProduct(product);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit "${product.name}" ajouté avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout du produit: $e'),
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
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => BarcodeScannerWidget(
            title: 'Scanner le code-barres du produit',
            onBarcodeScanned: (barcode) {
              // Le callback sera appelé automatiquement
            },
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _barcodeController.text = result;
        });

        // Vérifier si le produit existe déjà
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

      if (existingProduct != null && mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Produit existant'),
            content: Text(
              'Un produit avec ce code-barres existe déjà:\n\n'
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
            _barcodeController.clear();
          });
        }
      }
    } catch (e) {
      // Erreur silencieuse pour ne pas interrompre le processus
      debugPrint('Erreur lors de la vérification du produit existant: $e');
    }
  }
}