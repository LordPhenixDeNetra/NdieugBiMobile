import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../domain/models/connection.dart';
import '../domain/models/data_source.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'data_source_manager.dart';
import 'connection_manager.dart' as conn_manager;

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
}

enum SyncOperation {
  create,
  update,
  delete,
}

class SyncQueueItem {
  final int? id;
  final String tableName;
  final String recordId;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool synced;

  SyncQueueItem({
    this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation.name,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == map['operation'],
      ),
      data: jsonDecode(map['data']),
      createdAt: DateTime.parse(map['created_at']),
      synced: map['synced'] == 1,
    );
  }
}

class SyncResult {
  final bool success;
  final int syncedItems;
  final int failedItems;
  final List<String> errors;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.syncedItems,
    required this.failedItems,
    required this.errors,
    required this.timestamp,
  });
}

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final DataSourceManager _dataSourceManager = DataSourceManager();
  final conn_manager.ConnectionManager _connectionManager = conn_manager.ConnectionManager();
  
  SyncStatus _status = SyncStatus.idle;
  Timer? _autoSyncTimer;
  
  int _pendingItems = 0;
  DateTime? _lastSyncTime;
  SyncResult? _lastSyncResult;
  bool _autoSyncEnabled = true;
  bool _syncOnReconnect = true;
  bool _offlineFirstEnabled = true;

  // Getters
  SyncStatus get status => _status;
  int get pendingItems => _pendingItems;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncResult? get lastSyncResult => _lastSyncResult;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get syncOnReconnect => _syncOnReconnect;
  bool get offlineFirstEnabled => _offlineFirstEnabled;
  bool get isSyncing => _status == SyncStatus.syncing;

  String get statusMessage {
    switch (_status) {
      case SyncStatus.idle:
        return _pendingItems > 0 
            ? '$_pendingItems éléments en attente de synchronisation'
            : 'Synchronisé';
      case SyncStatus.syncing:
        return 'Synchronisation en cours...';
      case SyncStatus.success:
        return 'Synchronisation réussie';
      case SyncStatus.error:
        return 'Erreur de synchronisation';
      case SyncStatus.conflict:
        return 'Conflits détectés';
    }
  }

  // Initialize sync service
  Future<void> initialize() async {
    try {
      // DatabaseService s'initialise automatiquement
      await _dataSourceManager.initialize();
      await _connectionManager.initialize();
      
      await _updatePendingItemsCount();
      
      // Listen to connectivity changes
      _connectivityService.addListener(_onConnectivityChanged);
      
      // Start auto-sync if enabled
      if (_autoSyncEnabled) {
        _startAutoSync();
      }

      // Sync on reconnect if enabled
      if (_syncOnReconnect && _connectivityService.isOnline) {
        _scheduleSyncAfterDelay();
      }
    } catch (e) {
      debugPrint('Erreur d\'initialisation du service de synchronisation: $e');
    }
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && _syncOnReconnect && _pendingItems > 0) {
      _scheduleSyncAfterDelay();
    }
  }

  void _scheduleSyncAfterDelay() {
    Timer(const Duration(seconds: 2), () {
      if (_connectivityService.isOnline && _pendingItems > 0) {
        syncPendingItems();
      }
    });
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      AppConstants.autoSyncInterval,
      (_) {
        if (_connectivityService.isOnline && _pendingItems > 0) {
          syncPendingItems();
        }
      },
    );
  }

  // Add item to sync queue
  Future<void> addToSyncQueue({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final item = SyncQueueItem(
        tableName: tableName,
        recordId: recordId,
        operation: operation,
        data: data,
        createdAt: DateTime.now(),
      );

      await _databaseService.insert('sync_queue', item.toMap());
      await _updatePendingItemsCount();
      
      // Auto-sync if online and enabled
      if (_connectivityService.isOnline && _autoSyncEnabled) {
        _scheduleSyncAfterDelay();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout à la queue de synchronisation: $e');
    }
  }

  // Get pending sync items
  Future<List<SyncQueueItem>> getPendingItems() async {
    try {
      final results = await _databaseService.query(
        'sync_queue',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      return results.map((map) => SyncQueueItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des éléments en attente: $e');
      return [];
    }
  }

  // Sync pending items
  Future<SyncResult> syncPendingItems() async {
    if (_status == SyncStatus.syncing) {
      return _lastSyncResult ?? SyncResult(
        success: false,
        syncedItems: 0,
        failedItems: 0,
        errors: ['Synchronisation déjà en cours'],
        timestamp: DateTime.now(),
      );
    }

    if (!_connectivityService.isOnline) {
      return SyncResult(
        success: false,
        syncedItems: 0,
        failedItems: 0,
        errors: ['Pas de connexion Internet'],
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      final pendingItems = await getPendingItems();
      if (pendingItems.isEmpty) {
        final result = SyncResult(
          success: true,
          syncedItems: 0,
          failedItems: 0,
          errors: [],
          timestamp: DateTime.now(),
        );
        _updateSyncResult(result, SyncStatus.success);
        return result;
      }

      int syncedCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      for (final item in pendingItems) {
        try {
          final success = await _syncItem(item);
          if (success) {
            await _markItemAsSynced(item.id!);
            syncedCount++;
          } else {
            failedCount++;
            errors.add('Échec de synchronisation pour ${item.tableName}:${item.recordId}');
          }
        } catch (e) {
          failedCount++;
          errors.add('Erreur lors de la synchronisation de ${item.tableName}:${item.recordId}: $e');
        }
      }

      final result = SyncResult(
        success: failedCount == 0,
        syncedItems: syncedCount,
        failedItems: failedCount,
        errors: errors,
        timestamp: DateTime.now(),
      );

      _updateSyncResult(result, failedCount == 0 ? SyncStatus.success : SyncStatus.error);
      await _updatePendingItemsCount();

      return result;
    } catch (e) {
      final result = SyncResult(
        success: false,
        syncedItems: 0,
        failedItems: 0,
        errors: ['Erreur générale de synchronisation: $e'],
        timestamp: DateTime.now(),
      );
      _updateSyncResult(result, SyncStatus.error);
      return result;
    }
  }

  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/${item.tableName}';
      http.Response response;

      switch (item.operation) {
        case SyncOperation.create:
          response = await http.post(
            Uri.parse(url),
            headers: _getHeaders(),
            body: jsonEncode(item.data),
          ).timeout(const Duration(seconds: 30));
          break;

        case SyncOperation.update:
          response = await http.put(
            Uri.parse('$url/${item.recordId}'),
            headers: _getHeaders(),
            body: jsonEncode(item.data),
          ).timeout(const Duration(seconds: 30));
          break;

        case SyncOperation.delete:
          response = await http.delete(
            Uri.parse('$url/${item.recordId}'),
            headers: _getHeaders(),
          ).timeout(const Duration(seconds: 30));
          break;
      }

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation de l\'élément: $e');
      return false;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Add authentication headers here if needed
    };
  }

  Future<void> _markItemAsSynced(int itemId) async {
    await _databaseService.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> _updatePendingItemsCount() async {
    try {
      final results = await _databaseService.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0',
      );
      _pendingItems = results.first['count'] as int;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du nombre d\'éléments en attente: $e');
    }
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void _updateSyncResult(SyncResult result, SyncStatus status) {
    _lastSyncResult = result;
    _lastSyncTime = result.timestamp;
    _updateStatus(status);
  }

  // Clear synced items from queue
  Future<void> clearSyncedItems() async {
    try {
      await _databaseService.delete(
        'sync_queue',
        where: 'synced = ?',
        whereArgs: [1],
      );
      await _updatePendingItemsCount();
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des éléments synchronisés: $e');
    }
  }

  // Clear all sync queue
  Future<void> clearSyncQueue() async {
    try {
      await _databaseService.delete('sync_queue');
      await _updatePendingItemsCount();
    } catch (e) {
      debugPrint('Erreur lors du nettoyage de la queue de synchronisation: $e');
    }
  }

  // Configuration methods for new features
  void setOfflineFirstEnabled(bool enabled) {
    _offlineFirstEnabled = enabled;
    notifyListeners();
  }

  // Multi-source sync methods
  Future<SyncResult> syncAllSources({bool forceSync = false}) async {
    if (_status == SyncStatus.syncing && !forceSync) {
      return SyncResult(
        success: false,
        syncedItems: 0,
        failedItems: 0,
        errors: ['Synchronisation déjà en cours'],
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);
    
    try {
      int totalSynced = 0;
      int totalFailed = 0;
      List<String> allErrors = [];

      // Sync with different data sources based on strategy
      if (_offlineFirstEnabled) {
        final offlineResult = await _syncOfflineFirst();
        totalSynced += offlineResult.syncedItems;
        totalFailed += offlineResult.failedItems;
        allErrors.addAll(offlineResult.errors);
      } else {
        final onlineResult = await _syncOnlineFirst();
        totalSynced += onlineResult.syncedItems;
        totalFailed += onlineResult.failedItems;
        allErrors.addAll(onlineResult.errors);
      }

      // Sync with available connections
      final connectionResult = await _syncWithConnections();
      totalSynced += connectionResult.syncedItems;
      totalFailed += connectionResult.failedItems;
      allErrors.addAll(connectionResult.errors);

      final result = SyncResult(
        success: totalFailed == 0,
        syncedItems: totalSynced,
        failedItems: totalFailed,
        errors: allErrors,
        timestamp: DateTime.now(),
      );

      _updateSyncResult(result, totalFailed == 0 ? SyncStatus.success : SyncStatus.error);
      await _updatePendingItemsCount();
      
      return result;
      
    } catch (e) {
      final result = SyncResult(
        success: false,
        syncedItems: 0,
        failedItems: 0,
        errors: ['Erreur de synchronisation multi-sources: $e'],
        timestamp: DateTime.now(),
      );
      
      _updateSyncResult(result, SyncStatus.error);
      return result;
    }
  }

  Future<SyncResult> _syncOfflineFirst() async {
    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      // Process local changes first
      final localResult = await syncPendingItems();
      synced += localResult.syncedItems;
      failed += localResult.failedItems;
      errors.addAll(localResult.errors);
      
      // Then sync with remote sources if connected
      if (_connectivityService.isOnline) {
        final remoteResult = await _syncWithRemoteSources();
        synced += remoteResult.syncedItems;
        failed += remoteResult.failedItems;
        errors.addAll(remoteResult.errors);
      }
    } catch (e) {
      failed++;
      errors.add('Erreur sync offline-first: $e');
    }

    return SyncResult(
      success: failed == 0,
      syncedItems: synced,
      failedItems: failed,
      errors: errors,
      timestamp: DateTime.now(),
    );
  }

  Future<SyncResult> _syncOnlineFirst() async {
    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      // Try remote sources first if connected
      if (_connectivityService.isOnline) {
        final remoteResult = await _syncWithRemoteSources();
        synced += remoteResult.syncedItems;
        failed += remoteResult.failedItems;
        errors.addAll(remoteResult.errors);
      }
      
      // Always process local changes
      final localResult = await syncPendingItems();
      synced += localResult.syncedItems;
      failed += localResult.failedItems;
      errors.addAll(localResult.errors);
    } catch (e) {
      failed++;
      errors.add('Erreur sync online-first: $e');
    }

    return SyncResult(
      success: failed == 0,
      syncedItems: synced,
      failedItems: failed,
      errors: errors,
      timestamp: DateTime.now(),
    );
  }

  Future<SyncResult> _syncWithRemoteSources() async {
    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      final activeSources = _dataSourceManager.dataSources.where((ds) => ds.isActive).toList();
      
      for (final source in activeSources) {
        try {
          switch (source.type) {
            case DataSourceType.api:
              final result = await _syncWithAPI(source);
              synced += result.syncedItems;
              failed += result.failedItems;
              errors.addAll(result.errors);
              break;
            case DataSourceType.cloud:
              final result = await _syncWithGoogleSheets(source);
              synced += result.syncedItems;
              failed += result.failedItems;
              errors.addAll(result.errors);
              break;
            case DataSourceType.file:
              final result = await _syncWithExcel(source);
              synced += result.syncedItems;
              failed += result.failedItems;
              errors.addAll(result.errors);
              break;
            default:
              break;
          }
        } catch (e) {
          failed++;
          errors.add('Erreur sync source ${source.name}: $e');
        }
      }
    } catch (e) {
      failed++;
      errors.add('Erreur sync sources distantes: $e');
    }

    return SyncResult(
      success: failed == 0,
      syncedItems: synced,
      failedItems: failed,
      errors: errors,
      timestamp: DateTime.now(),
    );
  }

  Future<SyncResult> _syncWithConnections() async {
    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      final activeConnections = _connectionManager.connections.values
          .where((conn) => conn.status == ConnectionStatus.connected)
          .toList();
      
      for (final connection in activeConnections) {
        try {
          // Simuler la synchronisation des données via connexion
          final success = await _connectionManager.sendData(connection.config.name, {'sync': 'request'});
          if (success) {
            synced++;
          } else {
            failed++;
            errors.add('Échec sync connexion ${connection.config.name}');
          }
        } catch (e) {
          failed++;
          errors.add('Erreur sync connexion ${connection.config.name}: $e');
        }
      }
    } catch (e) {
      failed++;
      errors.add('Erreur sync connexions: $e');
    }

    return SyncResult(
      success: failed == 0,
      syncedItems: synced,
      failedItems: failed,
      errors: errors,
      timestamp: DateTime.now(),
    );
  }

  Future<SyncResult> _syncWithAPI(DataSourceConfig source) async {
    // Use existing sync logic but with specific API source
    return await syncPendingItems();
  }

  Future<SyncResult> _syncWithGoogleSheets(DataSourceConfig source) async {
    // Placeholder for Google Sheets sync implementation
    debugPrint('Sync avec Google Sheets: ${source.name}');
    return SyncResult(
      success: true,
      syncedItems: 0,
      failedItems: 0,
      errors: [],
      timestamp: DateTime.now(),
    );
  }

  Future<SyncResult> _syncWithExcel(DataSourceConfig source) async {
    // Placeholder for Excel sync implementation
    debugPrint('Sync avec Excel: ${source.name}');
    return SyncResult(
      success: true,
      syncedItems: 0,
      failedItems: 0,
      errors: [],
      timestamp: DateTime.now(),
    );
  }

  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
    if (enabled) {
      _startAutoSync();
    } else {
      _autoSyncTimer?.cancel();
    }
    notifyListeners();
  }

  void setSyncOnReconnect(bool enabled) {
    _syncOnReconnect = enabled;
    notifyListeners();
  }

  // Force sync
  Future<SyncResult> forcSync() async {
    return await syncPendingItems();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}