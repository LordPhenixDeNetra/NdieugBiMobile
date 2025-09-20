import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, AppConstants.databaseName);
      
      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation de la base de données: $e');
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // For now, we'll recreate all tables
      await _dropTables(db);
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Create products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        barcode TEXT UNIQUE NOT NULL,
        price REAL NOT NULL,
        cost_price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        min_quantity INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    // Create carts table
    await db.execute('''
      CREATE TABLE carts (
        id TEXT PRIMARY KEY,
        global_discount REAL NOT NULL DEFAULT 0.0,
        tax_rate REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        customer_id TEXT,
        metadata TEXT
      )
    ''');

    // Create cart_items table
    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        cart_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        added_at TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (cart_id) REFERENCES carts (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // Create invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT UNIQUE NOT NULL,
        subtotal REAL NOT NULL,
        total_discount REAL NOT NULL,
        tax_amount REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        payment_method TEXT,
        created_at TEXT NOT NULL,
        paid_at TEXT,
        customer_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        customer_email TEXT,
        notes TEXT,
        metadata TEXT
      )
    ''');

    // Create invoice_items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        product_barcode TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        added_at TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Create sync_queue table for offline operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Products indexes
    await db.execute('CREATE INDEX idx_products_barcode ON products (barcode)');
    await db.execute('CREATE INDEX idx_products_category ON products (category)');
    await db.execute('CREATE INDEX idx_products_is_active ON products (is_active)');
    await db.execute('CREATE INDEX idx_products_quantity ON products (quantity)');

    // Cart items indexes
    await db.execute('CREATE INDEX idx_cart_items_cart_id ON cart_items (cart_id)');
    await db.execute('CREATE INDEX idx_cart_items_product_id ON cart_items (product_id)');

    // Invoices indexes
    await db.execute('CREATE INDEX idx_invoices_number ON invoices (invoice_number)');
    await db.execute('CREATE INDEX idx_invoices_status ON invoices (status)');
    await db.execute('CREATE INDEX idx_invoices_created_at ON invoices (created_at)');
    await db.execute('CREATE INDEX idx_invoices_customer_id ON invoices (customer_id)');

    // Invoice items indexes
    await db.execute('CREATE INDEX idx_invoice_items_invoice_id ON invoice_items (invoice_id)');
    await db.execute('CREATE INDEX idx_invoice_items_product_id ON invoice_items (product_id)');

    // Sync queue indexes
    await db.execute('CREATE INDEX idx_sync_queue_synced ON sync_queue (synced)');
    await db.execute('CREATE INDEX idx_sync_queue_table_name ON sync_queue (table_name)');
  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS sync_queue');
    await db.execute('DROP TABLE IF EXISTS invoice_items');
    await db.execute('DROP TABLE IF EXISTS invoices');
    await db.execute('DROP TABLE IF EXISTS cart_items');
    await db.execute('DROP TABLE IF EXISTS carts');
    await db.execute('DROP TABLE IF EXISTS products');
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    try {
      return await db.insert(table, data);
    } catch (e) {
      throw Exception('Erreur lors de l\'insertion dans $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    try {
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Erreur lors de la requête sur $table: $e');
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    try {
      return await db.update(table, data, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de $table: $e');
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    try {
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw Exception('Erreur lors de la suppression dans $table: $e');
    }
  }

  // Raw query execution
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    try {
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw Exception('Erreur lors de l\'exécution de la requête SQL: $e');
    }
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    try {
      return await db.transaction(action);
    } catch (e) {
      throw Exception('Erreur lors de la transaction: $e');
    }
  }

  // Batch operations
  Future<List<dynamic>> batch(Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    try {
      operations(batch);
      return await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de l\'opération batch: $e');
    }
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA page_count');
    final pageCount = result.first['page_count'] as int;
    final pageSizeResult = await db.rawQuery('PRAGMA page_size');
    final pageSize = pageSizeResult.first['page_size'] as int;
    return pageCount * pageSize;
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Reset database (for testing or data reset)
  Future<void> resetDatabase() async {
    await close();
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, AppConstants.databaseName);
    await deleteDatabase(path);
    _database = await _initDatabase();
  }
}