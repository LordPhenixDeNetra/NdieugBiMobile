import 'package:flutter/foundation.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../data/repositories/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();
  
  Cart? _currentCart;
  bool _isLoading = false;
  String? _error;

  // Getters
  Cart? get currentCart => _currentCart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCart => _currentCart != null;
  bool get isEmpty => _currentCart?.items.isEmpty ?? true;
  int get itemCount => _currentCart?.items.length ?? 0;
  int get totalQuantity => _currentCart?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
  double get subtotal => _currentCart?.subtotal ?? 0.0;
  double get totalDiscount => _currentCart?.totalDiscount ?? 0.0;
  double get taxAmount => _currentCart?.taxAmount ?? 0.0;
  double get total => _currentCart?.total ?? 0.0;

  Future<void> createNewCart() async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.createCart();
    } catch (e) {
      _setError('Erreur lors de la création du panier: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCart(String cartId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.getCart(cartId);
    } catch (e) {
      _setError('Erreur lors du chargement du panier: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadActiveCart() async {
    _setLoading(true);
    _clearError();
    
    try {
      final carts = await _cartRepository.getActiveCarts();
      if (carts.isNotEmpty) {
        _currentCart = carts.first;
      }
    } catch (e) {
      _setError('Erreur lors du chargement du panier actif: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProduct(Product product, {int quantity = 1, double? customPrice}) async {
    if (_currentCart == null) {
      await createNewCart();
    }
    
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.addItem(
        _currentCart!.id,
        product,
        quantity,
      );
    } catch (e) {
      _setError('Erreur lors de l\'ajout du produit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeProduct(String productId) async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.removeItem(_currentCart!.id, productId);
    } catch (e) {
      _setError('Erreur lors de la suppression du produit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.updateQuantity(_currentCart!.id, productId, quantity);
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la quantité: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateItemDiscount(String productId, double discount) async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.updateItemDiscount(_currentCart!.id, productId, discount);
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la remise: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> applyGlobalDiscount(double discount) async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.applyGlobalDiscount(_currentCart!.id, discount);
    } catch (e) {
      _setError('Erreur lors de l\'application de la remise globale: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setTaxRate(double taxRate) async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.setTaxRate(_currentCart!.id, taxRate);
    } catch (e) {
      _setError('Erreur lors de la configuration de la taxe: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearCart() async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      _currentCart = await _cartRepository.clearCart(_currentCart!.id);
    } catch (e) {
      _setError('Erreur lors du vidage du panier: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCart() async {
    if (_currentCart == null) return;

    _setLoading(true);
    _clearError();
    
    try {
      await _cartRepository.deleteCart(_currentCart!.id);
      _currentCart = null;
    } catch (e) {
      _setError('Erreur lors de la suppression du panier: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  bool hasProduct(String productId) {
    return _currentCart?.items.any((item) => item.productId == productId) ?? false;
  }

  CartItem? getCartItem(String productId) {
    try {
      return _currentCart?.items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  int getProductQuantity(String productId) {
    final item = getCartItem(productId);
    return item?.quantity ?? 0;
  }

  double getProductTotal(String productId) {
    final item = getCartItem(productId);
    if (item == null) return 0.0;
    
    final itemTotal = item.unitPrice * item.quantity;
    final discountAmount = itemTotal * (item.discount / 100);
    return itemTotal - discountAmount;
  }

  // Validation methods
  bool canAddProduct(Product product, int quantity) {
    if (product.stock <= 0) return false;
    
    final currentQuantity = getProductQuantity(product.id);
    return (currentQuantity + quantity) <= product.stock;
  }

  String? getValidationError(Product product, int quantity) {
    if (product.stock <= 0) {
      return 'Produit en rupture de stock';
    }
    
    final currentQuantity = getProductQuantity(product.id);
    if ((currentQuantity + quantity) > product.stock) {
      return 'Stock insuffisant (disponible: ${product.stock - currentQuantity})';
    }
    
    return null;
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
    if (_currentCart != null) {
      await loadCart(_currentCart!.id);
    }
  }
}