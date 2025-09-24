import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../domain/models/data_source.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'google_sheets_service.dart';
import 'google_auth_service.dart';

/// Configuration d'une source de données
class DataSourceConfig {
  final DataSourceType type;
  final String name;
  final String? url;
  final Map<String, String>? headers;
  final Map<String, dynamic>? credentials;
  final bool isActive;
  final DateTime lastSync;
  final Map<String, dynamic>? metadata;

  const DataSourceConfig({
    required this.type,
    required this.name,
    this.url,
    this.headers,
    this.credentials,
    this.isActive = true,
    required this.lastSync,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'name': name,
      'url': url,
      'headers': headers != null ? jsonEncode(headers) : null,
      'credentials': credentials != null ? jsonEncode(credentials) : null,
      'is_active': isActive ? 1 : 0,
      'last_sync': lastSync.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory DataSourceConfig.fromMap(Map<String, dynamic> map) {
    return DataSourceConfig(
      type: DataSourceType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => DataSourceType.local,
      ),
      name: map['name'] as String,
      url: map['url'] as String?,
      headers: map['headers'] != null 
          ? Map<String, String>.from(jsonDecode(map['headers']))
          : null,
      credentials: map['credentials'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['credentials']))
          : null,
      isActive: (map['is_active'] as int) == 1,
      lastSync: DateTime.parse(map['last_sync'] as String),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata']))
          : null,
    );
  }
}

/// Résultat d'une opération de synchronisation
class DataSourceSyncResult {
  final DataSourceType sourceType;
  final bool success;
  final String? error;
  final int recordsProcessed;
  final int recordsSuccess;
  final int recordsError;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const DataSourceSyncResult({
    required this.sourceType,
    required this.success,
    this.error,
    this.recordsProcessed = 0,
    this.recordsSuccess = 0,
    this.recordsError = 0,
    required this.timestamp,
    this.details,
  });
}

/// Gestionnaire centralisé des sources de données
class DataSourceManager extends ChangeNotifier {
  static final DataSourceManager _instance = DataSourceManager._internal();
  factory DataSourceManager() => _instance;
  DataSourceManager._internal();

  final DatabaseService _databaseService = DatabaseService();
  // final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService(GoogleAuthService());

  final List<DataSourceConfig> _dataSources = [];
  final Map<DataSourceType, DataSourceSyncResult?> _lastSyncResults = {};
  bool _isInitialized = false;
  bool _isSyncing = false;

  // Getters
  List<DataSourceConfig> get dataSources => List.unmodifiable(_dataSources);
  Map<DataSourceType, DataSourceSyncResult?> get lastSyncResults => Map.unmodifiable(_lastSyncResults);
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;

  /// Initialise le gestionnaire de sources de données
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _createDataSourcesTable();
      await _loadDataSources();
      await _initializeDefaultSources();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'initialisation du DataSourceManager: $e');
      rethrow;
    }
  }

  /// Crée la table des sources de données
  Future<void> _createDataSourcesTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS data_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        url TEXT,
        headers TEXT,
        credentials TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        last_sync TEXT NOT NULL,
        metadata TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX IF NOT EXISTS idx_data_sources_type ON data_sources (type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_data_sources_active ON data_sources (is_active)');
  }

  /// Charge les sources de données depuis la base
  Future<void> _loadDataSources() async {
    final db = await _databaseService.database;
    final results = await db.query('data_sources', where: 'is_active = 1');
    
    _dataSources.clear();
    for (final result in results) {
      _dataSources.add(DataSourceConfig.fromMap(result));
    }
  }

  /// Initialise les sources par défaut
  Future<void> _initializeDefaultSources() async {
    // Source locale SQLite (toujours présente)
    if (!_dataSources.any((ds) => ds.type == DataSourceType.local)) {
      await addDataSource(DataSourceConfig(
        type: DataSourceType.local,
        name: 'Base de données locale',
        lastSync: DateTime.now(),
        metadata: {'description': 'Base de données SQLite locale'},
      ));
    }
  }

  /// Ajoute une nouvelle source de données
  Future<void> addDataSource(DataSourceConfig config) async {
    try {
      final db = await _databaseService.database;
      await db.insert('data_sources', {
        ...config.toMap(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _dataSources.add(config);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la source de données: $e');
      rethrow;
    }
  }

  /// Met à jour une source de données
  Future<void> updateDataSource(String name, DataSourceConfig config) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'data_sources',
        {
          ...config.toMap(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'name = ?',
        whereArgs: [name],
      );

      final index = _dataSources.indexWhere((ds) => ds.name == name);
      if (index != -1) {
        _dataSources[index] = config;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la source de données: $e');
      rethrow;
    }
  }

  /// Supprime une source de données
  Future<void> removeDataSource(String name) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'data_sources',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'name = ?',
        whereArgs: [name],
      );

      _dataSources.removeWhere((ds) => ds.name == name);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la source de données: $e');
      rethrow;
    }
  }

  /// Synchronise toutes les sources actives
  Future<List<DataSourceSyncResult>> syncAllSources() async {
    if (_isSyncing) {
      throw Exception('Synchronisation déjà en cours');
    }

    _isSyncing = true;
    notifyListeners();

    final results = <DataSourceSyncResult>[];

    try {
      for (final source in _dataSources.where((ds) => ds.isActive)) {
        try {
          final result = await _syncDataSource(source);
          results.add(result);
          _lastSyncResults[source.type] = result;
        } catch (e) {
          final errorResult = DataSourceSyncResult(
            sourceType: source.type,
            success: false,
            error: e.toString(),
            timestamp: DateTime.now(),
          );
          results.add(errorResult);
          _lastSyncResults[source.type] = errorResult;
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return results;
  }

  /// Synchronise une source spécifique
  Future<DataSourceSyncResult> syncDataSource(DataSourceType type) async {
    final source = _dataSources.firstWhere(
      (ds) => ds.type == type && ds.isActive,
      orElse: () => throw Exception('Source de données non trouvée ou inactive: $type'),
    );

    final result = await _syncDataSource(source);
    _lastSyncResults[type] = result;
    notifyListeners();
    return result;
  }

  /// Synchronise une source de données spécifique
  Future<DataSourceSyncResult> _syncDataSource(DataSourceConfig source) async {
    switch (source.type) {
      case DataSourceType.local:
        return await _syncLocalDatabase(source);
      case DataSourceType.file:
        return await _syncExcelFile(source);
      case DataSourceType.cloud:
        return await _syncGoogleSheets(source);
      case DataSourceType.api:
        return await _syncCloudApi(source);
      case DataSourceType.database:
        return await _syncBluetooth(source);
      case DataSourceType.remote:
        return await _syncWifi(source);
      case DataSourceType.cache:
        return await _syncLocalDatabase(source);
    }
  }

  /// Synchronise la base de données locale
  Future<DataSourceSyncResult> _syncLocalDatabase(DataSourceConfig source) async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT * FROM ${source.name} ORDER BY id DESC LIMIT ?',
        [source.credentials?['limit'] ?? 100],
      );
      
      return DataSourceSyncResult(
        sourceType: source.type,
        success: true,
        recordsProcessed: result.length,
        recordsSuccess: result.length,
        timestamp: DateTime.now(),
        details: {'records': result},
      );
    } catch (e) {
      return DataSourceSyncResult(
        sourceType: source.type,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Synchronise un fichier Excel
  Future<DataSourceSyncResult> _syncExcelFile(DataSourceConfig source) async {
    try {
      if (source.url == null) {
        throw Exception('URL du fichier Excel non spécifiée');
      }

      // TODO: Implémenter la lecture de fichiers Excel
      // Pour l'instant, retourner un succès simulé
      return DataSourceSyncResult(
        sourceType: source.type,
        success: true,
        recordsProcessed: 0,
        recordsSuccess: 0,
        timestamp: DateTime.now(),
        details: {'message': 'Synchronisation Excel à implémenter'},
      );
    } catch (e) {
      return DataSourceSyncResult(
        sourceType: source.type,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Synchronise Google Sheets
  Future<DataSourceSyncResult> _syncGoogleSheets(DataSourceConfig source) async {
    try {
      if (!_connectivityService.isOnline) {
        throw Exception('Connexion Internet requise pour Google Sheets');
      }

      // Initialiser le service Google Sheets avec les credentials
      await _googleSheetsService.initialize();
      
      // Authentifier si nécessaire
      if (!_googleSheetsService.isAuthenticated) {
        await _googleSheetsService.authenticate();
      }

      // Connecter à la feuille de calcul
      final spreadsheetId = source.credentials?['spreadsheetId'] as String?;
      if (spreadsheetId == null) {
        throw Exception('ID de la feuille de calcul Google Sheets non spécifié');
      }

      await _googleSheetsService.connectToSpreadsheet(spreadsheetId);

      // Synchroniser les données
      final syncResult = await _googleSheetsService.syncFromSheets();
      
      return DataSourceSyncResult(
        sourceType: source.type,
        success: true,
        recordsProcessed: (syncResult['recordsProcessed'] as int?) ?? 0,
        recordsSuccess: (syncResult['recordsSuccess'] as int?) ?? 0,
        timestamp: DateTime.now(),
        details: syncResult,
      );
    } catch (e) {
      return DataSourceSyncResult(
        sourceType: source.type,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Synchronise avec l'API Cloud
  Future<DataSourceSyncResult> _syncCloudApi(DataSourceConfig source) async {
    try {
      if (!_connectivityService.isOnline) {
        throw Exception('Connexion Internet requise pour l\'API Cloud');
      }

      if (source.url == null) {
        throw Exception('URL de l\'API non spécifiée');
      }

      // TODO: Implémenter la synchronisation avec l'API REST
      return DataSourceSyncResult(
        sourceType: source.type,
        success: true,
        recordsProcessed: 0,
        recordsSuccess: 0,
        timestamp: DateTime.now(),
        details: {'message': 'Synchronisation API Cloud à implémenter'},
      );
    } catch (e) {
      return DataSourceSyncResult(
        sourceType: source.type,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Synchronise via Bluetooth
  Future<DataSourceSyncResult> _syncBluetooth(DataSourceConfig source) async {
    try {
      // TODO: Implémenter la synchronisation Bluetooth
      return DataSourceSyncResult(
        sourceType: source.type,
        success: true,
        recordsProcessed: 0,
        recordsSuccess: 0,
        timestamp: DateTime.now(),
        details: {'message': 'Synchronisation Bluetooth à implémenter'},
      );
    } catch (e) {
      return DataSourceSyncResult(
        sourceType: source.type,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Synchronise via WiFi local
  Future<DataSourceSyncResult> _syncWifi(DataSourceConfig source) async {
    try {
      if (source.url == null) {
        throw Exception('URL du serveur WiFi non spécifiée');
      }

      // TODO: Implémenter la synchronisation WiFi locale
      return DataSourceSyncResult(
        sourceType: source.type,
        success: true,
        recordsProcessed: 0,
        recordsSuccess: 0,
        timestamp: DateTime.now(),
        details: {'message': 'Synchronisation WiFi locale à implémenter'},
      );
    } catch (e) {
      return DataSourceSyncResult(
        sourceType: source.type,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Obtient les statistiques des sources de données
  Map<String, dynamic> getDataSourceStatistics() {
    final totalSources = _dataSources.length;
    final activeSources = _dataSources.where((source) => source.isActive).length;
    final successfulSyncs = _lastSyncResults.values
        .whereType<DataSourceSyncResult>()
        .where((result) => result.success)
        .length;
    final failedSyncs = _lastSyncResults.values
        .whereType<DataSourceSyncResult>()
        .where((result) => !result.success)
        .length;

    return {
      'totalSources': totalSources,
      'activeSources': activeSources,
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
      'lastSyncTime': _lastSyncResults.values
          .whereType<DataSourceSyncResult>()
          .map((result) => result.timestamp)
          .fold<DateTime?>(null, (latest, current) => 
              latest == null || current.isAfter(latest) ? current : latest),
    };
  }

  /// Charge les sources de données (méthode publique)
  Future<void> loadDataSources() async {
    await _loadDataSources();
    notifyListeners();
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _dataSources.clear();
    _lastSyncResults.clear();
    super.dispose();
  }
}