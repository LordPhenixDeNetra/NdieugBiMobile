import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Get unique categories
  List<String> get categories {
    final categories = _products.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get low stock products
  List<Product> get lowStockProducts {
    return _products.where((p) => p.stock <= p.minStock).toList();
  }

  // Get out of stock products
  List<Product> get outOfStockProducts {
    return _products.where((p) => p.stock <= 0).toList();
  }

  // Statistics
  int get totalProducts => _products.length;
  double get totalInventoryValue {
    return _products.fold(0.0, (sum, product) => sum + (product.price * product.stock));
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _products = await _productRepository.getAllProducts();
      _applyFilters();
    } catch (e) {
      _setError('Erreur lors du chargement des produits: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createProduct(Product product) async {
    _setLoading(true);
    _clearError();
    
    try {
      final createdProduct = await _productRepository.createProduct(product);
      _products.add(createdProduct);
      _applyFilters();
    } catch (e) {
      _setError('Erreur lors de la création du produit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(Product product) async {
    _setLoading(true);
    _clearError();
    
    try {
      final updatedProduct = await _productRepository.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _applyFilters();
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour du produit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _productRepository.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      _applyFilters();
    } catch (e) {
      _setError('Erreur lors de la suppression du produit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStock(String productId, int newStock) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _productRepository.updateStock(productId, newStock);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(quantity: newStock);
        _applyFilters();
      }
    } catch (e) {
      _setError('Erreur lors de la mise à jour du stock: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> bulkUpdateStock(Map<String, int> stockUpdates) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _productRepository.bulkUpdateStock(stockUpdates);
      
      // Update local products
      for (final entry in stockUpdates.entries) {
        final index = _products.indexWhere((p) => p.id == entry.key);
        if (index != -1) {
          _products[index] = _products[index].copyWith(quantity: entry.value);
        }
      }
      _applyFilters();
    } catch (e) {
      _setError('Erreur lors de la mise à jour en lot du stock: $e');
    } finally {
      _setLoading(false);
    }
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void sortProducts(String sortBy, {bool ascending = true}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _sortBy = 'name';
    _sortAscending = true;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProducts = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) {
        return product.category == _selectedCategory;
      }).toList();
    }

    // Apply sorting
    _filteredProducts.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'stock':
          comparison = a.stock.compareTo(b.stock);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Product? getProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((product) => product.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> refresh() async {
    await loadProducts();
  }
}