import '../models/cart_model.dart';
import '../models/cart_item_model.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import 'product_repository.dart';

class CartRepository {
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  final ProductRepository _productRepository = ProductRepository();

  static const String _cartTableName = 'carts';
  static const String _cartItemTableName = 'cart_items';

  // Create cart
  Future<Cart> createCart({String? customerId}) async {
    try {
      final cart = Cart(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: [],
        globalDiscount: 0.0,
        taxRate: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerId: customerId,
      );

      final cartModel = CartModel.fromEntity(cart);
      final cartMap = cartModel.toMap();

      // Save to local database
      await _databaseService.insert(_cartTableName, cartMap);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartTableName,
        recordId: cart.id,
        operation: SyncOperation.create,
        data: cartMap,
      );

      return cart;
    } catch (e) {
      throw Exception('Erreur lors de la création du panier: $e');
    }
  }

  // Get cart by ID
  Future<Cart?> getCartById(String cartId) async {
    try {
      final cartResults = await _databaseService.query(
        _cartTableName,
        where: 'id = ?',
        whereArgs: [cartId],
        limit: 1,
      );

      if (cartResults.isEmpty) return null;

      final cartMap = cartResults.first;
      final cartItems = await _getCartItems(cartId);

      final cart = CartModel.fromMap(cartMap).toEntity();
      return cart.copyWith(items: cartItems);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du panier: $e');
    }
  }

  // Get current active cart
  Future<Cart?> getCurrentCart({String? customerId}) async {
    try {
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (customerId != null) {
        whereClause += ' AND customer_id = ?';
        whereArgs.add(customerId);
      }

      final cartResults = await _databaseService.query(
        _cartTableName,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (cartResults.isEmpty) {
        // Create a new cart if none exists
        return await createCart(customerId: customerId);
      }

      final cartId = cartResults.first['id'] as String;
      return await getCartById(cartId);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du panier actuel: $e');
    }
  }

  // Get cart items
  Future<List<CartItem>> _getCartItems(String cartId) async {
    try {
      final itemResults = await _databaseService.query(
        _cartItemTableName,
        where: 'cart_id = ?',
        whereArgs: [cartId],
        orderBy: 'added_at ASC',
      );

      List<CartItem> items = [];
      for (final itemMap in itemResults) {
        final productId = itemMap['product_id'] as String;
        final product = await _productRepository.getProductById(productId);
        
        if (product != null) {
          final cartItem = CartItemModel.fromMap(itemMap, product).toEntity();
          items.add(cartItem);
        }
      }

      return items;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des articles du panier: $e');
    }
  }

  // Add item to cart
  Future<Cart> addItemToCart(String cartId, Product product, int quantity, {double discount = 0.0}) async {
    try {
      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé');
      }

      // Check if item already exists in cart
      final existingItemIndex = cart.items.indexWhere((item) => item.productId == product.id);
      
      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = cart.items[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;
        return await updateCartItemQuantity(cartId, existingItem.id, newQuantity);
      } else {
        // Add new item
        final cartItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
          unitPrice: product.price,
          discount: discount,
          addedAt: DateTime.now(),
        );

        final cartItemModel = CartItemModel.fromEntity(cartItem);
        final cartItemMap = cartItemModel.toMap();

        // Save cart item to database
        await _databaseService.insert(_cartItemTableName, cartItemMap);

        // Add to sync queue
        await _syncService.addToSyncQueue(
          tableName: _cartItemTableName,
          recordId: cartItem.id,
          operation: SyncOperation.create,
          data: cartItemMap,
        );

        // Update cart timestamp
        await _updateCartTimestamp(cartId);

        return await getCartById(cartId) ?? cart;
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'article au panier: $e');
    }
  }

  // Update cart item quantity
  Future<Cart> updateCartItemQuantity(String cartId, String itemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        return await removeItemFromCart(cartId, itemId);
      }

      final updatedRows = await _databaseService.update(
        _cartItemTableName,
        {'quantity': newQuantity},
        where: 'id = ? AND cart_id = ?',
        whereArgs: [itemId, cartId],
      );

      if (updatedRows == 0) {
        throw Exception('Article du panier non trouvé');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartItemTableName,
        recordId: itemId,
        operation: SyncOperation.update,
        data: {'id': itemId, 'quantity': newQuantity},
      );

      // Update cart timestamp
      await _updateCartTimestamp(cartId);

      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé après mise à jour');
      }

      return cart;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la quantité: $e');
    }
  }

  // Remove item from cart
  Future<Cart> removeItemFromCart(String cartId, String itemId) async {
    try {
      final deletedRows = await _databaseService.delete(
        _cartItemTableName,
        where: 'id = ? AND cart_id = ?',
        whereArgs: [itemId, cartId],
      );

      if (deletedRows == 0) {
        throw Exception('Article du panier non trouvé');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartItemTableName,
        recordId: itemId,
        operation: SyncOperation.delete,
        data: {'id': itemId},
      );

      // Update cart timestamp
      await _updateCartTimestamp(cartId);

      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé après suppression');
      }

      return cart;
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'article: $e');
    }
  }

  // Update cart item discount
  Future<Cart> updateCartItemDiscount(String cartId, String itemId, double discount) async {
    try {
      final updatedRows = await _databaseService.update(
        _cartItemTableName,
        {'discount': discount},
        where: 'id = ? AND cart_id = ?',
        whereArgs: [itemId, cartId],
      );

      if (updatedRows == 0) {
        throw Exception('Article du panier non trouvé');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartItemTableName,
        recordId: itemId,
        operation: SyncOperation.update,
        data: {'id': itemId, 'discount': discount},
      );

      // Update cart timestamp
      await _updateCartTimestamp(cartId);

      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé après mise à jour');
      }

      return cart;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la remise: $e');
    }
  }

  // Apply global discount to cart
  Future<Cart> applyGlobalDiscount(String cartId, double discount) async {
    try {
      final updatedRows = await _databaseService.update(
        _cartTableName,
        {
          'global_discount': discount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [cartId],
      );

      if (updatedRows == 0) {
        throw Exception('Panier non trouvé');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartTableName,
        recordId: cartId,
        operation: SyncOperation.update,
        data: {'id': cartId, 'global_discount': discount},
      );

      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé après mise à jour');
      }

      return cart;
    } catch (e) {
      throw Exception('Erreur lors de l\'application de la remise globale: $e');
    }
  }

  // Set tax rate for cart
  Future<Cart> setTaxRate(String cartId, double taxRate) async {
    try {
      final updatedRows = await _databaseService.update(
        _cartTableName,
        {
          'tax_rate': taxRate,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [cartId],
      );

      if (updatedRows == 0) {
        throw Exception('Panier non trouvé');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartTableName,
        recordId: cartId,
        operation: SyncOperation.update,
        data: {'id': cartId, 'tax_rate': taxRate},
      );

      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé après mise à jour');
      }

      return cart;
    } catch (e) {
      throw Exception('Erreur lors de la définition du taux de taxe: $e');
    }
  }

  // Clear cart
  Future<Cart> clearCart(String cartId) async {
    try {
      // Delete all cart items
      await _databaseService.delete(
        _cartItemTableName,
        where: 'cart_id = ?',
        whereArgs: [cartId],
      );

      // Add cart items deletion to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartItemTableName,
        recordId: cartId,
        operation: SyncOperation.delete,
        data: {'cart_id': cartId},
      );

      // Reset cart discounts and update timestamp
      await _databaseService.update(
        _cartTableName,
        {
          'global_discount': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [cartId],
      );

      // Add cart update to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartTableName,
        recordId: cartId,
        operation: SyncOperation.update,
        data: {'id': cartId, 'global_discount': 0.0},
      );

      final cart = await getCartById(cartId);
      if (cart == null) {
        throw Exception('Panier non trouvé après vidage');
      }

      return cart;
    } catch (e) {
      throw Exception('Erreur lors du vidage du panier: $e');
    }
  }

  // Delete cart
  Future<void> deleteCart(String cartId) async {
    try {
      // Delete all cart items first
      await _databaseService.delete(
        _cartItemTableName,
        where: 'cart_id = ?',
        whereArgs: [cartId],
      );

      // Delete cart
      final deletedRows = await _databaseService.delete(
        _cartTableName,
        where: 'id = ?',
        whereArgs: [cartId],
      );

      if (deletedRows == 0) {
        throw Exception('Panier non trouvé');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _cartTableName,
        recordId: cartId,
        operation: SyncOperation.delete,
        data: {'id': cartId},
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du panier: $e');
    }
  }

  // Get all carts
  Future<List<Cart>> getAllCarts({String? customerId, int? limit}) async {
    try {
      String? whereClause;
      List<dynamic>? whereArgs;

      if (customerId != null) {
        whereClause = 'customer_id = ?';
        whereArgs = [customerId];
      }

      final cartResults = await _databaseService.query(
        _cartTableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'updated_at DESC',
        limit: limit,
      );

      List<Cart> carts = [];
      for (final cartMap in cartResults) {
        final cartId = cartMap['id'] as String;
        final cart = await getCartById(cartId);
        if (cart != null) {
          carts.add(cart);
        }
      }

      return carts;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paniers: $e');
    }
  }

  // Update cart timestamp
  Future<void> _updateCartTimestamp(String cartId) async {
    await _databaseService.update(
      _cartTableName,
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  // Get cart (alias for getCartById)
  Future<Cart?> getCart(String cartId) async {
    return await getCartById(cartId);
  }

  // Get active carts
  Future<List<Cart>> getActiveCarts() async {
    try {
      final cartMaps = await _databaseService.query(
        _cartTableName,
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'updated_at DESC',
      );

      final carts = <Cart>[];
      for (final cartMap in cartMaps) {
        final cartId = cartMap['id'] as String;
        final cartItems = await _getCartItems(cartId);
        
        final cartModel = CartModel.fromMap(cartMap);
        final cart = cartModel.copyWith(items: cartItems).toEntity();
        carts.add(cart);
      }

      return carts;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paniers actifs: $e');
    }
  }

  // Add item (alias for addItemToCart)
  Future<Cart> addItem(String cartId, Product product, int quantity, {double discount = 0.0}) async {
    return await addItemToCart(cartId, product, quantity, discount: discount);
  }

  // Remove item from cart (alias for removeItemFromCart)
  Future<Cart> removeItem(String cartId, String productId) async {
    // Find the cart item by product ID
    final cartItems = await _databaseService.query(
      _cartItemTableName,
      where: 'cart_id = ? AND product_id = ?',
      whereArgs: [cartId, productId],
    );

    if (cartItems.isEmpty) {
      throw Exception('Article du panier non trouvé');
    }

    final itemId = cartItems.first['id'] as String;
    return await removeItemFromCart(cartId, itemId);
  }

  // Update quantity (alias for updateCartItemQuantity)
  Future<Cart> updateQuantity(String cartId, String productId, int quantity) async {
    // Find the cart item by product ID
    final cartItems = await _databaseService.query(
      _cartItemTableName,
      where: 'cart_id = ? AND product_id = ?',
      whereArgs: [cartId, productId],
    );

    if (cartItems.isEmpty) {
      throw Exception('Article du panier non trouvé');
    }

    final itemId = cartItems.first['id'] as String;
    return await updateCartItemQuantity(cartId, itemId, quantity);
  }

  // Update item discount (alias for updateCartItemDiscount)
  Future<Cart> updateItemDiscount(String cartId, String productId, double discount) async {
    // Find the cart item by product ID
    final cartItems = await _databaseService.query(
      _cartItemTableName,
      where: 'cart_id = ? AND product_id = ?',
      whereArgs: [cartId, productId],
    );

    if (cartItems.isEmpty) {
      throw Exception('Article du panier non trouvé');
    }

    final itemId = cartItems.first['id'] as String;
    return await updateCartItemDiscount(cartId, itemId, discount);
  }

  // Get cart statistics
  Future<Map<String, dynamic>> getCartStatistics() async {
    try {
      final totalCartsResult = await _databaseService.rawQuery('''
        SELECT COUNT(*) as total FROM $_cartTableName
      ''');

      final activeCartsResult = await _databaseService.rawQuery('''
        SELECT COUNT(*) as active FROM $_cartTableName c
        WHERE EXISTS (SELECT 1 FROM $_cartItemTableName ci WHERE ci.cart_id = c.id)
      ''');

      final totalItemsResult = await _databaseService.rawQuery('''
        SELECT SUM(quantity) as total_items FROM $_cartItemTableName
      ''');

      return {
        'totalCarts': totalCartsResult.first['total'] ?? 0,
        'activeCarts': activeCartsResult.first['active'] ?? 0,
        'totalItems': totalItemsResult.first['total_items'] ?? 0,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques du panier: $e');
    }
  }
}