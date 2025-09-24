import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/data_source.dart';
import '../domain/models/product.dart';
import '../domain/models/invoice.dart';
import 'database_service.dart';
import 'data_source_service.dart';
import 'websocket_service.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

/// Types de synchronisation
enum SyncType {
  manual,
  automatic,
  realTime,
}

/// Direction de synchronisation
enum SyncDirection {
  upload,    // Local vers externe
  download,  // Externe vers local
  bidirectional, // Dans les deux sens
}

/// Statut de synchronisation
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
  conflict,
}

/// Configuration de synchronisation
class SyncConfig {
  final SyncType type;
  final SyncDirection direction;
  final Duration interval;
  final bool syncProducts;
  final bool syncInvoices;
  final bool syncOnWifiOnly;
  final bool resolveConflictsAutomatically;
  final DateTime? lastSync;

  const SyncConfig({
    this.type = SyncType.manual,
    this.direction = SyncDirection.bidirectional,
    this.interval = const Duration(minutes: 30),
    this.syncProducts = true,
    this.syncInvoices = true,
    this.syncOnWifiOnly = true,
    this.resolveConflictsAutomatically = false,
    this.lastSync,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'direction': direction.name,
      'interval_minutes': interval.inMinutes,
      'sync_products': syncProducts,
      'sync_invoices': syncInvoices,
      'sync_on_wifi_only': syncOnWifiOnly,
      'resolve_conflicts_automatically': resolveConflictsAutomatically,
      'last_sync': lastSync?.toIso8601String(),
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      type: SyncType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncType.manual,
      ),
      direction: SyncDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => SyncDirection.bidirectional,
      ),
      interval: Duration(minutes: json['interval_minutes'] ?? 30),
      syncProducts: json['sync_products'] ?? true,
      syncInvoices: json['sync_invoices'] ?? true,
      syncOnWifiOnly: json['sync_on_wifi_only'] ?? true,
      resolveConflictsAutomatically: json['resolve_conflicts_automatically'] ?? false,
      lastSync: json['last_sync'] != null 
          ? DateTime.parse(json['last_sync'])
          : null,
    );
  }
}

/// Résultat de synchronisation
class SyncResult {
  final bool success;
  final int itemsSynced;
  final int conflicts;
  final List<String> errors;
  final DateTime timestamp;
  final Duration duration;

  const SyncResult({
    required this.success,
    this.itemsSynced = 0,
    this.conflicts = 0,
    this.errors = const [],
    required this.timestamp,
    required this.duration,
  });
}

/// Gestionnaire de synchronisation des données
class SyncManager extends ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final DatabaseService _databaseService = DatabaseService();
  final DataSourceService _dataSourceService = DataSourceService();
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();

  SyncConfig _config = const SyncConfig();
  SyncStatus _status = SyncStatus.idle;
  Timer? _autoSyncTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _webSocketSubscription;

  bool _isInitialized = false;
  DateTime? _lastSyncAttempt;
  SyncResult? _lastResult;

  // Getters
  SyncConfig get config => _config;
  SyncStatus get status => _status;
  bool get isInitialized => _isInitialized;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  SyncResult? get lastResult => _lastResult;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Initialise le gestionnaire de synchronisation
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadConfig();
      await _setupConnectivityListener();
      await _setupWebSocketListener();
      
      if (_config.type == SyncType.automatic) {
        _startAutoSync();
      }

      _isInitialized = true;
      notifyListeners();
      debugPrint('SyncManager initialisé');
    } catch (e) {
      debugPrint('Erreur d\'initialisation du SyncManager: $e');
      rethrow;
    }
  }

  /// Configure la synchronisation
  Future<void> configure(SyncConfig config) async {
    _config = config;
    await _saveConfig();
    
    // Redémarre la synchronisation automatique si nécessaire
    if (config.type == SyncType.automatic) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }

    notifyListeners();
    debugPrint('Configuration de synchronisation mise à jour');
  }

  /// Lance une synchronisation manuelle
  Future<SyncResult> sync({bool force = false}) async {
    if (_status == SyncStatus.syncing && !force) {
      throw Exception('Synchronisation déjà en cours');
    }

    _status = SyncStatus.syncing;
    _lastSyncAttempt = DateTime.now();
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    int itemsSynced = 0;
    int conflicts = 0;
    List<String> errors = [];

    try {
      // Vérification de la connectivité
      if (_config.syncOnWifiOnly) {
        final isWifiConnected = _connectivityService.isWifiConnected;
        if (!isWifiConnected) {
          throw Exception('WiFi requis pour la synchronisation');
        }
      }

      // Vérification de la source de données externe
      final currentSource = _dataSourceService.getCurrentDataSource();
      if (currentSource?.type != DataSourceType.remote) {
        throw Exception('Aucune source de données externe configurée');
      }

      // Synchronisation des produits
      if (_config.syncProducts) {
        final productResult = await _syncProducts();
        itemsSynced += productResult.itemsSynced;
        conflicts += productResult.conflicts;
        errors.addAll(productResult.errors);
      }

      // Synchronisation des factures
      if (_config.syncInvoices) {
        final invoiceResult = await _syncInvoices();
        itemsSynced += invoiceResult.itemsSynced;
        conflicts += invoiceResult.conflicts;
        errors.addAll(invoiceResult.errors);
      }

      stopwatch.stop();
      
      _status = errors.isEmpty ? SyncStatus.completed : SyncStatus.error;
      _lastResult = SyncResult(
        success: errors.isEmpty,
        itemsSynced: itemsSynced,
        conflicts: conflicts,
        errors: errors,
        timestamp: DateTime.now(),
        duration: stopwatch.elapsed,
      );

      // Mise à jour de la configuration avec la dernière synchronisation
      await configure(_config.copyWith(lastSync: DateTime.now()));

      debugPrint('Synchronisation terminée: ${_lastResult!.itemsSynced} éléments, ${_lastResult!.conflicts} conflits');
      
    } catch (e) {
      stopwatch.stop();
      _status = SyncStatus.error;
      _lastResult = SyncResult(
        success: false,
        errors: [e.toString()],
        timestamp: DateTime.now(),
        duration: stopwatch.elapsed,
      );
      debugPrint('Erreur de synchronisation: $e');
    }

    notifyListeners();
    return _lastResult!;
  }

  /// Synchronise les produits
  Future<SyncResult> _syncProducts() async {
    int itemsSynced = 0;
    int conflicts = 0;
    List<String> errors = [];
    final stopwatch = Stopwatch()..start();

    try {
      if (_config.direction == SyncDirection.upload || _config.direction == SyncDirection.bidirectional) {
        // Upload des produits locaux
        final localProducts = await _databaseService.getAllProducts();
        for (final productData in localProducts) {
          try {
            final product = Product.fromMap(productData);
            final response = await _apiService.post<Map<String, dynamic>>(
              '/products',
              data: product.toJson(),
            );
            if (response.success) {
              itemsSynced++;
            } else {
              errors.add('Erreur upload produit ${product.id}: ${response.error}');
            }
          } catch (e) {
            errors.add('Erreur upload produit ${productData['id']}: $e');
          }
        }
      }

      if (_config.direction == SyncDirection.download || _config.direction == SyncDirection.bidirectional) {
        // Download des produits externes
        final response = await _apiService.get<List<dynamic>>('/products');
        if (response.success && response.data != null) {
          for (final productData in response.data!) {
            try {
              final product = Product.fromJson(productData as Map<String, dynamic>);
              
              // Vérification des conflits
              final existingProductData = await _databaseService.getProductById(product.id?.toString() ?? '');
              if (existingProductData != null) {
                final existingProduct = Product.fromMap(existingProductData);
                if (existingProduct.updatedAt.isAfter(product.updatedAt)) {
                  conflicts++;
                  if (!_config.resolveConflictsAutomatically) {
                    continue; // Skip ce produit en cas de conflit
                  }
                }
              }

              await _databaseService.insertOrUpdateProduct(product.toMap());
              itemsSynced++;
            } catch (e) {
              errors.add('Erreur traitement produit: $e');
            }
          }
        }
      }
    } catch (e) {
      errors.add('Erreur synchronisation produits: $e');
    }

    stopwatch.stop();
    return SyncResult(
      success: errors.isEmpty,
      itemsSynced: itemsSynced,
      conflicts: conflicts,
      errors: errors,
      timestamp: DateTime.now(),
      duration: stopwatch.elapsed,
    );
  }

  /// Synchronise les factures
  Future<SyncResult> _syncInvoices() async {
    int itemsSynced = 0;
    int conflicts = 0;
    List<String> errors = [];
    final stopwatch = Stopwatch()..start();

    try {
      if (_config.direction == SyncDirection.upload || _config.direction == SyncDirection.bidirectional) {
        // Upload des factures locales
        final localInvoices = await _databaseService.getAllInvoices();
        for (final invoiceData in localInvoices) {
          try {
            final invoice = Invoice.fromMap(invoiceData);
            final response = await _apiService.post<Map<String, dynamic>>(
              '/invoices',
              data: invoice.toJson(),
            );
            if (response.success) {
              itemsSynced++;
            } else {
              errors.add('Erreur upload facture ${invoice.id}: ${response.error}');
            }
          } catch (e) {
            errors.add('Erreur upload facture ${invoiceData['id']}: $e');
          }
        }
      }

      if (_config.direction == SyncDirection.download || _config.direction == SyncDirection.bidirectional) {
        // Download des factures externes
        final response = await _apiService.get<List<dynamic>>('/invoices');
        if (response.success && response.data != null) {
          for (final invoiceData in response.data!) {
            try {
              final invoice = Invoice.fromJson(invoiceData as Map<String, dynamic>);
              
              // Vérification des conflits
              final existingInvoiceData = await _databaseService.getInvoiceById(invoice.id?.toString() ?? '');
              if (existingInvoiceData != null) {
                final existingInvoice = Invoice.fromMap(existingInvoiceData);
                if (existingInvoice.updatedAt.isAfter(invoice.updatedAt)) {
                  conflicts++;
                  if (!_config.resolveConflictsAutomatically) {
                    continue; // Skip cette facture en cas de conflit
                  }
                }
              }

              await _databaseService.insertOrUpdateInvoice(invoice.toMap());
              itemsSynced++;
            } catch (e) {
              errors.add('Erreur traitement facture: $e');
            }
          }
        }
      }
    } catch (e) {
      errors.add('Erreur synchronisation factures: $e');
    }

    stopwatch.stop();
    return SyncResult(
      success: errors.isEmpty,
      itemsSynced: itemsSynced,
      conflicts: conflicts,
      errors: errors,
      timestamp: DateTime.now(),
      duration: stopwatch.elapsed,
    );
  }

  /// Démarre la synchronisation automatique
  void _startAutoSync() {
    _stopAutoSync();
    _autoSyncTimer = Timer.periodic(_config.interval, (timer) async {
      if (_status != SyncStatus.syncing) {
        try {
          await sync();
        } catch (e) {
          debugPrint('Erreur synchronisation automatique: $e');
        }
      }
    });
    debugPrint('Synchronisation automatique démarrée (intervalle: ${_config.interval})');
  }

  /// Arrête la synchronisation automatique
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Configure l'écoute de la connectivité
  Future<void> _setupConnectivityListener() async {
    _connectivitySubscription = _connectivityService.connectivityStream.listen((status) {
      final isConnected = status == ConnectivityStatus.online;
      if (isConnected && _config.type == SyncType.automatic) {
        // Relance la synchronisation automatique si la connexion est rétablie
        _startAutoSync();
      } else if (!isConnected) {
        // Arrête la synchronisation automatique si pas de connexion
        _stopAutoSync();
      }
    });
  }

  /// Configure l'écoute des WebSockets pour la synchronisation en temps réel
  Future<void> _setupWebSocketListener() async {
    if (_config.type == SyncType.realTime) {
      _webSocketService.onMessage = (message) {
        _handleRealTimeUpdate(message);
      };
    }
  }

  /// Gère les mises à jour en temps réel via WebSocket
  void _handleRealTimeUpdate(Map<String, dynamic> message) async {
    try {
      final type = message['type'] as String?;
      final data = message['data'] as Map<String, dynamic>?;

      if (data == null) return;

      switch (type) {
        case 'product_updated':
          final product = Product.fromJson(data);
          await _databaseService.insertOrUpdateProduct(product.toMap());
          debugPrint('Produit mis à jour en temps réel: ${product.id}');
          break;
        case 'invoice_updated':
          final invoice = Invoice.fromJson(data);
          await _databaseService.insertOrUpdateInvoice(invoice.toMap());
          debugPrint('Facture mise à jour en temps réel: ${invoice.id}');
          break;
        case 'product_deleted':
          final productId = data['id'] as String;
          await _databaseService.deleteProduct(productId);
          debugPrint('Produit supprimé en temps réel: $productId');
          break;
        case 'invoice_deleted':
          final invoiceId = data['id'] as String;
          await _databaseService.deleteInvoice(invoiceId);
          debugPrint('Facture supprimée en temps réel: $invoiceId');
          break;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur traitement mise à jour temps réel: $e');
    }
  }

  /// Charge la configuration depuis les préférences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('sync_config');
      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        _config = SyncConfig.fromJson(configMap);
      }
    } catch (e) {
      debugPrint('Erreur chargement config sync: $e');
    }
  }

  /// Sauvegarde la configuration dans les préférences
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sync_config', jsonEncode(_config.toJson()));
    } catch (e) {
      debugPrint('Erreur sauvegarde config sync: $e');
    }
  }

  @override
  void dispose() {
    _stopAutoSync();
    _connectivitySubscription?.cancel();
    _webSocketSubscription?.cancel();
    super.dispose();
  }
}

/// Extension pour SyncConfig
extension SyncConfigExtension on SyncConfig {
  SyncConfig copyWith({
    SyncType? type,
    SyncDirection? direction,
    Duration? interval,
    bool? syncProducts,
    bool? syncInvoices,
    bool? syncOnWifiOnly,
    bool? resolveConflictsAutomatically,
    DateTime? lastSync,
  }) {
    return SyncConfig(
      type: type ?? this.type,
      direction: direction ?? this.direction,
      interval: interval ?? this.interval,
      syncProducts: syncProducts ?? this.syncProducts,
      syncInvoices: syncInvoices ?? this.syncInvoices,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      resolveConflictsAutomatically: resolveConflictsAutomatically ?? this.resolveConflictsAutomatically,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}