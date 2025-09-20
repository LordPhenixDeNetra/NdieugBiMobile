import '../models/product_model.dart';
import '../../domain/entities/product.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';

class ProductRepository {
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();

  static const String _tableName = 'products';

  // Create product
  Future<Product> createProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      final productMap = productModel.toMap();

      // Save to local database
      await _databaseService.insert(_tableName, productMap);

      // Add to sync queue for online synchronization
      await _syncService.addToSyncQueue(
        tableName: _tableName,
        recordId: product.id,
        operation: SyncOperation.create,
        data: productMap,
      );

      return product;
    } catch (e) {
      throw Exception('Erreur lors de la création du produit: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final results = await _databaseService.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return ProductModel.fromMap(results.first).toEntity();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du produit: $e');
    }
  }

  // Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final results = await _databaseService.query(
        _tableName,
        where: 'barcode = ?',
        whereArgs: [barcode],
        limit: 1,
      );

      if (results.isEmpty) return null;

      return ProductModel.fromMap(results.first).toEntity();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du produit par code-barres: $e');
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts({
    bool activeOnly = true,
    String? category,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      String? whereClause;
      List<dynamic> whereArgs = [];

      // Build where clause
      List<String> conditions = [];
      
      if (activeOnly) {
        conditions.add('is_active = ?');
        whereArgs.add(1);
      }

      if (category != null && category.isNotEmpty) {
        conditions.add('category = ?');
        whereArgs.add(category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('(name LIKE ? OR description LIKE ? OR barcode LIKE ?)');
        final searchPattern = '%$searchQuery%';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }

      if (conditions.isNotEmpty) {
        whereClause = conditions.join(' AND ');
      }

      final results = await _databaseService.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => ProductModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    return await getAllProducts(category: category);
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    return await getAllProducts(searchQuery: query);
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final results = await _databaseService.rawQuery('''
        SELECT * FROM $_tableName 
        WHERE is_active = 1 AND quantity <= min_quantity 
        ORDER BY quantity ASC
      ''');

      return results.map((map) => ProductModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits en rupture: $e');
    }
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final results = await _databaseService.rawQuery('''
        SELECT DISTINCT category FROM $_tableName 
        WHERE is_active = 1 
        ORDER BY category ASC
      ''');

      return results.map((map) => map['category'] as String).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      final productMap = productModel.toMap();

      // Update in local database
      final updatedRows = await _databaseService.update(
        _tableName,
        productMap,
        where: 'id = ?',
        whereArgs: [product.id],
      );

      if (updatedRows == 0) {
        throw Exception('Produit non trouvé pour la mise à jour');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _tableName,
        recordId: product.id,
        operation: SyncOperation.update,
        data: productMap,
      );

      return product;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du produit: $e');
    }
  }

  // Update product quantity
  Future<Product> updateProductQuantity(String productId, int newQuantity) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Produit non trouvé');
      }

      final updatedProduct = product.copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
      );

      return await updateProduct(updatedProduct);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la quantité: $e');
    }
  }

  // Adjust stock (add or remove quantity)
  Future<Product> adjustStock(String productId, int adjustment, {String? reason}) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Produit non trouvé');
      }

      final newQuantity = product.quantity + adjustment;
      if (newQuantity < 0) {
        throw Exception('La quantité ne peut pas être négative');
      }

      return await updateProductQuantity(productId, newQuantity);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajustement du stock: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Produit non trouvé');
      }

      // Soft delete by setting is_active to false
      final updatedProduct = product.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await updateProduct(updatedProduct);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du produit: $e');
    }
  }

  // Permanently delete product
  Future<void> permanentlyDeleteProduct(String productId) async {
    try {
      final deletedRows = await _databaseService.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (deletedRows == 0) {
        throw Exception('Produit non trouvé pour la suppression');
      }

      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _tableName,
        recordId: productId,
        operation: SyncOperation.delete,
        data: {'id': productId},
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression permanente du produit: $e');
    }
  }

  // Restore product
  Future<Product> restoreProduct(String productId) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Produit non trouvé');
      }

      final restoredProduct = product.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      return await updateProduct(restoredProduct);
    } catch (e) {
      throw Exception('Erreur lors de la restauration du produit: $e');
    }
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final totalProductsResult = await _databaseService.rawQuery('''
        SELECT COUNT(*) as total FROM $_tableName WHERE is_active = 1
      ''');

      final lowStockResult = await _databaseService.rawQuery('''
        SELECT COUNT(*) as low_stock FROM $_tableName 
        WHERE is_active = 1 AND quantity <= min_quantity
      ''');

      final outOfStockResult = await _databaseService.rawQuery('''
        SELECT COUNT(*) as out_of_stock FROM $_tableName 
        WHERE is_active = 1 AND quantity = 0
      ''');

      final totalValueResult = await _databaseService.rawQuery('''
        SELECT SUM(quantity * cost_price) as total_value FROM $_tableName 
        WHERE is_active = 1
      ''');

      final categoriesResult = await _databaseService.rawQuery('''
        SELECT COUNT(DISTINCT category) as categories FROM $_tableName 
        WHERE is_active = 1
      ''');

      return {
        'totalProducts': totalProductsResult.first['total'] ?? 0,
        'lowStockProducts': lowStockResult.first['low_stock'] ?? 0,
        'outOfStockProducts': outOfStockResult.first['out_of_stock'] ?? 0,
        'totalInventoryValue': totalValueResult.first['total_value'] ?? 0.0,
        'totalCategories': categoriesResult.first['categories'] ?? 0,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // Bulk operations
  Future<void> bulkCreateProducts(List<Product> products) async {
    try {
      await _databaseService.transaction((txn) async {
        for (final product in products) {
          final productModel = ProductModel.fromEntity(product);
          final productMap = productModel.toMap();
          
          await txn.insert(_tableName, productMap);
          
          // Add to sync queue
          await _syncService.addToSyncQueue(
            tableName: _tableName,
            recordId: product.id,
            operation: SyncOperation.create,
            data: productMap,
          );
        }
      });
    } catch (e) {
      throw Exception('Erreur lors de la création en lot des produits: $e');
    }
  }

  Future<void> bulkUpdateProducts(List<Product> products) async {
    try {
      await _databaseService.transaction((txn) async {
        for (final product in products) {
          final productModel = ProductModel.fromEntity(product);
          final productMap = productModel.toMap();
          
          await txn.update(
            _tableName,
            productMap,
            where: 'id = ?',
            whereArgs: [product.id],
          );
          
          // Add to sync queue
          await _syncService.addToSyncQueue(
            tableName: _tableName,
            recordId: product.id,
            operation: SyncOperation.update,
            data: productMap,
          );
        }
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour en lot des produits: $e');
    }
  }

  // Update stock for a single product
  Future<void> updateStock(String productId, int newStock) async {
    try {
      // Get current product to preserve other fields
      final results = await _databaseService.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      
      if (results.isEmpty) {
        throw Exception('Produit non trouvé avec l\'ID: $productId');
      }
      
      final currentProduct = ProductModel.fromMap(results.first);
      final updatedProduct = currentProduct.copyWith(
        quantity: newStock,
        updatedAt: DateTime.now(),
      );
      
      await _databaseService.update(
        _tableName,
        updatedProduct.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );
      
      // Add to sync queue
      await _syncService.addToSyncQueue(
        tableName: _tableName,
        recordId: productId,
        operation: SyncOperation.update,
        data: updatedProduct.toMap(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du stock: $e');
    }
  }

  // Bulk update stock for multiple products
  Future<void> bulkUpdateStock(Map<String, int> stockUpdates) async {
    try {
      await _databaseService.transaction((txn) async {
        for (final entry in stockUpdates.entries) {
          final productId = entry.key;
          final newQuantity = entry.value;
          
          // Get current product to preserve other fields
          final results = await txn.query(
            _tableName,
            where: 'id = ?',
            whereArgs: [productId],
            limit: 1,
          );
          
          if (results.isNotEmpty) {
            final currentProduct = ProductModel.fromMap(results.first);
            final updatedProduct = currentProduct.copyWith(
              quantity: newQuantity,
              updatedAt: DateTime.now(),
            );
            
            await txn.update(
              _tableName,
              updatedProduct.toMap(),
              where: 'id = ?',
              whereArgs: [productId],
            );
            
            // Add to sync queue
            await _syncService.addToSyncQueue(
              tableName: _tableName,
              recordId: productId,
              operation: SyncOperation.update,
              data: updatedProduct.toMap(),
            );
          }
        }
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour en lot du stock: $e');
    }
  }

  // Check if barcode exists
  Future<bool> barcodeExists(String barcode, {String? excludeProductId}) async {
    try {
      String whereClause = 'barcode = ?';
      List<dynamic> whereArgs = [barcode];

      if (excludeProductId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeProductId);
      }

      final results = await _databaseService.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return results.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du code-barres: $e');
    }
  }
}