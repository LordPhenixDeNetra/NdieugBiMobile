import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';

enum OfflineOperationType {
  create,
  update,
  delete,
  read,
}

class OfflineOperation {
  final String id;
  final String tableName;
  final String recordId;
  final OfflineOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool synced;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.synced = false,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'type': type.name,
      'data': jsonEncode(data),
      'timestamp': timestamp.toIso8601String(),
      'synced': synced ? 1 : 0,
      'retry_count': retryCount,
    };
  }

  factory OfflineOperation.fromMap(Map<String, dynamic> map) {
    return OfflineOperation(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      type: OfflineOperationType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      data: jsonDecode(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
      synced: map['synced'] == 1,
      retryCount: map['retry_count'] ?? 0,
    );
  }

  OfflineOperation copyWith({
    String? id,
    String? tableName,
    String? recordId,
    OfflineOperationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? synced,
    int? retryCount,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class OfflineFirstService extends ChangeNotifier {
  static final OfflineFirstService _instance = OfflineFirstService._internal();
  factory OfflineFirstService() => _instance;
  OfflineFirstService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();

  bool _isInitialized = false;
  Timer? _syncTimer;
  final Duration _syncInterval = const Duration(minutes: 5);
  final int _maxRetryCount = 3;

  // Cache for offline data
  final Map<String, Map<String, dynamic>> _localCache = {};
  final List<OfflineOperation> _pendingOperations = [];

  bool get isInitialized => _isInitialized;
  int get pendingOperationsCount => _pendingOperations.length;
  bool get hasLocalData => _localCache.isNotEmpty;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // DatabaseService s'initialise automatiquement
      await _createOfflineTablesIfNeeded();
      await _loadPendingOperations();
      await _loadLocalCache();

      // Listen to connectivity changes
      _connectivityService.addListener(_onConnectivityChanged);

      // Start periodic sync
      _startPeriodicSync();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'initialisation du service offline-first: $e');
    }
  }

  Future<void> _createOfflineTablesIfNeeded() async {
    final db = await _databaseService.database;
    
    // Create offline operations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_operations (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Create offline cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_cache (
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        PRIMARY KEY (table_name, record_id)
      )
    ''');
  }

  Future<void> _loadPendingOperations() async {
    try {
      final results = await _databaseService.query(
        'offline_operations',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );

      _pendingOperations.clear();
      _pendingOperations.addAll(
        results.map((map) => OfflineOperation.fromMap(map)),
      );
    } catch (e) {
      debugPrint('Erreur lors du chargement des opérations en attente: $e');
    }
  }

  Future<void> _loadLocalCache() async {
    try {
      final results = await _databaseService.query('offline_cache');
      
      _localCache.clear();
      for (final row in results) {
        final tableName = row['table_name'] as String;
        final recordId = row['record_id'] as String;
        final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        
        _localCache[tableName] ??= {};
        _localCache[tableName]![recordId] = data;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du cache local: $e');
    }
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && _pendingOperations.isNotEmpty) {
      // Delay sync to ensure connection is stable
      Timer(const Duration(seconds: 3), () {
        if (_connectivityService.isOnline) {
          _syncPendingOperations();
        }
      });
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_connectivityService.isOnline && _pendingOperations.isNotEmpty) {
        _syncPendingOperations();
      }
    });
  }

  // CRUD Operations with offline-first strategy
  Future<Map<String, dynamic>?> read(String tableName, String recordId) async {
    // Try local cache first
    if (_localCache[tableName]?.containsKey(recordId) == true) {
      return _localCache[tableName]![recordId];
    }

    // Try local database
    try {
      final results = await _databaseService.query(
        tableName,
        where: 'id = ?',
        whereArgs: [recordId],
      );

      if (results.isNotEmpty) {
        final data = results.first;
        await _updateLocalCache(tableName, recordId, data);
        return data;
      }
    } catch (e) {
      debugPrint('Erreur lors de la lecture locale: $e');
    }

    // If online, try to fetch from remote
    if (_connectivityService.isOnline) {
      try {
        // This would be implemented with actual API call
        // For now, return null to indicate not found
        return null;
      } catch (e) {
        debugPrint('Erreur lors de la lecture distante: $e');
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> readAll(String tableName) async {
    List<Map<String, dynamic>> results = [];

    // Get from local database first
    try {
      results = await _databaseService.query(tableName);
      
      // Update cache with local data
      for (final row in results) {
        final recordId = row['id']?.toString();
        if (recordId != null) {
          await _updateLocalCache(tableName, recordId, row);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la lecture de toutes les données locales: $e');
    }

    return results;
  }

  Future<bool> create(String tableName, Map<String, dynamic> data) async {
    final recordId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    data['id'] = recordId;

    try {
      // Save locally first
      await _databaseService.insert(tableName, data);
      await _updateLocalCache(tableName, recordId, data);

      // Add to pending operations for sync
      await _addPendingOperation(
        tableName: tableName,
        recordId: recordId,
        type: OfflineOperationType.create,
        data: data,
      );

      // Try immediate sync if online
      if (_connectivityService.isOnline) {
        _syncPendingOperations();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la création: $e');
      return false;
    }
  }

  Future<bool> update(String tableName, String recordId, Map<String, dynamic> data) async {
    try {
      // Update locally first
      await _databaseService.update(
        tableName,
        data,
        where: 'id = ?',
        whereArgs: [recordId],
      );
      await _updateLocalCache(tableName, recordId, data);

      // Add to pending operations for sync
      await _addPendingOperation(
        tableName: tableName,
        recordId: recordId,
        type: OfflineOperationType.update,
        data: data,
      );

      // Try immediate sync if online
      if (_connectivityService.isOnline) {
        _syncPendingOperations();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  Future<bool> delete(String tableName, String recordId) async {
    try {
      // Delete locally first
      await _databaseService.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [recordId],
      );
      await _removeFromLocalCache(tableName, recordId);

      // Add to pending operations for sync
      await _addPendingOperation(
        tableName: tableName,
        recordId: recordId,
        type: OfflineOperationType.delete,
        data: {'id': recordId},
      );

      // Try immediate sync if online
      if (_connectivityService.isOnline) {
        _syncPendingOperations();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return false;
    }
  }

  Future<void> _addPendingOperation({
    required String tableName,
    required String recordId,
    required OfflineOperationType type,
    required Map<String, dynamic> data,
  }) async {
    final operation = OfflineOperation(
      id: '${tableName}_${recordId}_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      tableName: tableName,
      recordId: recordId,
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    await _databaseService.insert('offline_operations', operation.toMap());
    _pendingOperations.add(operation);
  }

  Future<void> _updateLocalCache(String tableName, String recordId, Map<String, dynamic> data) async {
    _localCache[tableName] ??= {};
    _localCache[tableName]![recordId] = data;

    // Update cache table
    final db = await _databaseService.database;
    await db.insert(
      'offline_cache',
      {
        'table_name': tableName,
        'record_id': recordId,
        'data': jsonEncode(data),
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _removeFromLocalCache(String tableName, String recordId) async {
    _localCache[tableName]?.remove(recordId);

    // Remove from cache table
    await _databaseService.delete(
      'offline_cache',
      where: 'table_name = ? AND record_id = ?',
      whereArgs: [tableName, recordId],
    );
  }

  Future<void> _syncPendingOperations() async {
    if (!_connectivityService.isOnline || _pendingOperations.isEmpty) {
      return;
    }

    final operationsToSync = List<OfflineOperation>.from(_pendingOperations);
    
    for (final operation in operationsToSync) {
      try {
        final success = await _syncOperation(operation);
        
        if (success) {
          await _markOperationAsSynced(operation);
          _pendingOperations.remove(operation);
        } else {
          await _incrementRetryCount(operation);
          
          // Remove operation if max retries exceeded
          if (operation.retryCount >= _maxRetryCount) {
            await _removeFailedOperation(operation);
            _pendingOperations.remove(operation);
          }
        }
      } catch (e) {
        debugPrint('Erreur lors de la synchronisation de l\'opération ${operation.id}: $e');
        await _incrementRetryCount(operation);
      }
    }

    notifyListeners();
  }

  Future<bool> _syncOperation(OfflineOperation operation) async {
    try {
      // Convert to sync service operation
      SyncOperation syncOp;
      switch (operation.type) {
        case OfflineOperationType.create:
          syncOp = SyncOperation.create;
          break;
        case OfflineOperationType.update:
          syncOp = SyncOperation.update;
          break;
        case OfflineOperationType.delete:
          syncOp = SyncOperation.delete;
          break;
        default:
          return true; // Skip read operations
      }

      // Add to sync service queue
      await _syncService.addToSyncQueue(
        tableName: operation.tableName,
        recordId: operation.recordId,
        operation: syncOp,
        data: operation.data,
      );

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
      return false;
    }
  }

  Future<void> _markOperationAsSynced(OfflineOperation operation) async {
    await _databaseService.update(
      'offline_operations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  Future<void> _incrementRetryCount(OfflineOperation operation) async {
    final newRetryCount = operation.retryCount + 1;
    await _databaseService.update(
      'offline_operations',
      {'retry_count': newRetryCount},
      where: 'id = ?',
      whereArgs: [operation.id],
    );

    // Update in memory
    final index = _pendingOperations.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      _pendingOperations[index] = operation.copyWith(retryCount: newRetryCount);
    }
  }

  Future<void> _removeFailedOperation(OfflineOperation operation) async {
    await _databaseService.delete(
      'offline_operations',
      where: 'id = ?',
      whereArgs: [operation.id],
    );
    debugPrint('Opération supprimée après échec répété: ${operation.id}');
  }

  // Utility methods
  Future<void> clearCache() async {
    _localCache.clear();
    await _databaseService.delete('offline_cache');
    notifyListeners();
  }

  Future<void> clearPendingOperations() async {
    _pendingOperations.clear();
    await _databaseService.delete('offline_operations');
    notifyListeners();
  }

  Future<void> forceSyncAll() async {
    if (_connectivityService.isOnline) {
      await _syncPendingOperations();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}