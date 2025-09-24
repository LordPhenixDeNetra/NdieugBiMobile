import 'dart:async';
import 'package:flutter/foundation.dart';
import 'google_sheets_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

/// Service de synchronisation automatique avec Google Sheets
class AutoSyncService extends ChangeNotifier {
  final GoogleSheetsService _googleSheetsService;
  final DatabaseService _databaseService;
  final ConnectivityService _connectivityService;

  // Configuration de synchronisation
  Duration _syncInterval = const Duration(minutes: 15);
  bool _isAutoSyncEnabled = false;
  bool _isSyncing = false;
  bool _isRunning = false;
  DateTime? _lastSyncTime;
  String? _error;

  // Timer pour la synchronisation automatique
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  // Statistiques de synchronisation
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  Map<String, DateTime> _lastSheetSync = {};

  // Configuration de retry
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const Duration _exponentialBackoffBase = Duration(seconds: 2);

  // État des erreurs
  String? _lastError;
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;

  AutoSyncService(
    this._googleSheetsService,
    this._databaseService,
    this._connectivityService,
  );

  // Getters
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  bool get isSyncing => _isSyncing;
  bool get isRunning => _isRunning;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get error => _error;
  Duration get syncInterval => _syncInterval;
  int get successfulSyncs => _successfulSyncs;
  int get failedSyncs => _failedSyncs;
  Map<String, DateTime> get lastSheetSync => Map.unmodifiable(_lastSheetSync);
  String? get lastError => _lastError;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get lastFailureTime => _lastFailureTime;

  /// Initialise le service de synchronisation automatique
  Future<void> initialize() async {
    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (status) {
        if (status == ConnectivityStatus.online && _isAutoSyncEnabled && !_isSyncing) {
          // Synchroniser immédiatement quand la connexion est rétablie
          _scheduleSyncIfNeeded();
        }
      },
    );
  }

  /// Active ou désactive la synchronisation automatique
  Future<void> setAutoSyncEnabled(bool enabled) async {
    if (_isAutoSyncEnabled == enabled) return;

    _isAutoSyncEnabled = enabled;
    
    if (enabled) {
      await startAutoSync();
    } else {
      stopAutoSync();
    }
    
    notifyListeners();
  }

  /// Configure l'intervalle de synchronisation
  Future<void> setSyncInterval(Duration interval) async {
    if (interval.inMinutes < 1) {
      throw ArgumentError('L\'intervalle de synchronisation doit être d\'au moins 1 minute');
    }

    _syncInterval = interval;
    
    // Redémarrer le timer si la synchronisation automatique est active
    if (_isAutoSyncEnabled) {
      stopAutoSync();
      await startAutoSync();
    }
    
    notifyListeners();
  }

  /// Démarre la synchronisation automatique avec gestion d'erreurs
  Future<void> startAutoSync() async {
    if (_isRunning) return;

    _isRunning = true;
    _lastSyncTime = DateTime.now();
    notifyListeners();

    debugPrint('Démarrage de la synchronisation automatique');

    // Démarrer le timer avec gestion d'erreurs
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      try {
        await _performSyncWithRetry();
      } catch (e) {
        debugPrint('Erreur critique dans la synchronisation automatique: $e');
        _handleCriticalError(e);
      }
    });

    // Effectuer une synchronisation initiale
    try {
      await _performSyncWithRetry();
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation initiale: $e');
      _handleCriticalError(e);
    }
  }

  /// Arrête la synchronisation automatique
  void stopAutoSync() {
    if (!_isRunning) return;

    _isRunning = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    
    debugPrint('Synchronisation automatique arrêtée');
    notifyListeners();
  }

  /// Planifie une synchronisation si les conditions sont remplies
  void _scheduleSyncIfNeeded() {
    if (!_connectivityService.hasInternetAccess || 
        !_googleSheetsService.isAuthenticated || 
        _isSyncing) {
      return;
    }

    // Vérifier si assez de temps s'est écoulé depuis la dernière sync
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < _syncInterval) {
        return;
      }
    }

    // Lancer la synchronisation
    _performSyncWithRetry();
  }

  /// Effectue une synchronisation manuelle
  Future<bool> performManualSync() async {
    if (_isSyncing) {
      _setError('Une synchronisation est déjà en cours');
      return false;
    }

    if (!_connectivityService.hasInternetAccess) {
      _setError('Aucune connexion Internet disponible');
      return false;
    }

    if (!_googleSheetsService.isAuthenticated) {
      _setError('Authentification Google Sheets requise');
      return false;
    }

    try {
      await _performSyncWithRetry();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Effectue une synchronisation avec logique de retry
  Future<void> _performSyncWithRetry() async {
    int retryCount = 0;
    
    while (retryCount <= _maxRetries) {
      try {
        await _performSync();
        
        // Réinitialiser les compteurs d'erreur en cas de succès
        _consecutiveFailures = 0;
        _lastError = null;
        _lastFailureTime = null;
        
        debugPrint('Synchronisation réussie');
        return;
        
      } catch (e) {
        retryCount++;
        _consecutiveFailures++;
        _lastError = e.toString();
        _lastFailureTime = DateTime.now();
        
        debugPrint('Échec de synchronisation (tentative $retryCount/$_maxRetries): $e');
        
        if (retryCount <= _maxRetries) {
          // Calculer le délai avec backoff exponentiel
          final delay = _calculateRetryDelay(retryCount);
          debugPrint('Nouvelle tentative dans ${delay.inSeconds} secondes...');
          
          await Future.delayed(delay);
        } else {
          // Toutes les tentatives ont échoué
          debugPrint('Toutes les tentatives de synchronisation ont échoué');
          _handleSyncFailure(e);
          rethrow;
        }
      }
    }
  }

  /// Calcule le délai de retry avec backoff exponentiel
  Duration _calculateRetryDelay(int retryCount) {
    final baseDelay = _exponentialBackoffBase.inMilliseconds;
    final exponentialDelay = baseDelay * (1 << (retryCount - 1)); // 2^(retryCount-1)
    return Duration(milliseconds: exponentialDelay.clamp(
      _retryDelay.inMilliseconds,
      Duration(minutes: 5).inMilliseconds, // Maximum 5 minutes
    ));
  }

  /// Gère les erreurs critiques
  void _handleCriticalError(dynamic error) {
    debugPrint('Erreur critique détectée: $error');
    
    // Arrêter la synchronisation automatique si trop d'échecs consécutifs
    if (_consecutiveFailures >= _maxRetries * 2) {
      debugPrint('Trop d\'échecs consécutifs, arrêt de la synchronisation automatique');
      stopAutoSync();
    }
    
    notifyListeners();
  }

  /// Gère les échecs de synchronisation
  void _handleSyncFailure(dynamic error) {
    debugPrint('Échec de synchronisation: $error');
    
    // Notifier les listeners de l'erreur
    notifyListeners();
    
    // Optionnel: Envoyer une notification à l'utilisateur
    _notifyUserOfSyncFailure(error);
  }

  /// Notifie l'utilisateur des échecs de synchronisation
  void _notifyUserOfSyncFailure(dynamic error) {
    // Cette méthode peut être étendue pour envoyer des notifications push
    // ou afficher des messages dans l'interface utilisateur
    debugPrint('Notification utilisateur: Échec de synchronisation - $error');
  }

  /// Effectue la synchronisation avec gestion d'erreurs détaillée
  Future<void> _performSync() async {
    if (!_connectivityService.hasInternetAccess) {
      throw Exception('Pas de connexion Internet disponible');
    }

    if (!_googleSheetsService.isAuthenticated) {
      throw Exception('Authentification Google Sheets requise');
    }

    if (_isSyncing) return;

    _isSyncing = true;
    _setError(null);
    notifyListeners();

    try {
      // Synchronisation bidirectionnelle avec gestion d'erreurs
      await _performBidirectionalSync();
      
      _lastSyncTime = DateTime.now();
      _successfulSyncs++;
      notifyListeners();
      
    } catch (e) {
      _failedSyncs++;
      _setError('Erreur de synchronisation: $e');
      debugPrint('Erreur lors de la synchronisation: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Effectue une synchronisation bidirectionnelle avec gestion d'erreurs
  Future<void> _performBidirectionalSync() async {
    try {
      // 1. Synchroniser les données locales vers Google Sheets
      await _syncLocalToSheets();
      
      // 2. Synchroniser les données de Google Sheets vers local
      await _syncSheetsToLocal();
      
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation bidirectionnelle: $e');
      rethrow;
    }
  }

  /// Synchronise les données locales vers Google Sheets avec gestion d'erreurs
  Future<void> _syncLocalToSheets() async {
    try {
      final localData = await _getLocalDataForSync();
      
      if (localData.isNotEmpty) {
        final success = await _googleSheetsService.syncToSheets(localData);
        if (!success) {
          throw Exception('Échec de synchronisation vers Google Sheets');
        }
        debugPrint('Données locales synchronisées vers Google Sheets');
      }
      
    } catch (e) {
      debugPrint('Erreur synchronisation locale vers Sheets: $e');
      rethrow;
    }
  }

  /// Synchronise les données de Google Sheets vers local avec gestion d'erreurs
  Future<void> _syncSheetsToLocal() async {
    try {
      final sheetsData = await _googleSheetsService.syncFromSheets();
      
      if (sheetsData.isNotEmpty) {
        await _updateLocalDataFromSheets(sheetsData);
        debugPrint('Données Google Sheets synchronisées vers local');
      }
      
    } catch (e) {
      debugPrint('Erreur synchronisation Sheets vers local: $e');
      rethrow;
    }
  }

  /// Met à jour les données locales depuis Google Sheets avec gestion d'erreurs
  Future<void> _updateLocalDataFromSheets(Map<String, List<Map<String, dynamic>>> sheetsData) async {
    try {
      // Traiter chaque type de données avec gestion d'erreurs individuelle
      for (final entry in sheetsData.entries) {
        final sheetName = entry.key;
        final data = entry.value;
        
        try {
          switch (sheetName.toLowerCase()) {
            case 'produits':
              await _updateProductsFromSheets(data);
              break;
            case 'clients':
              await _updateClientsFromSheets(data);
              break;
            case 'factures':
              await _updateInvoicesFromSheets(data);
              break;
            case 'articles_facture':
              await _updateInvoiceItemsFromSheets(data);
              break;
            default:
              debugPrint('Type de feuille non reconnu: $sheetName');
          }
        } catch (e) {
          debugPrint('Erreur mise à jour $sheetName: $e');
          // Continuer avec les autres feuilles même si une échoue
        }
      }
      
    } catch (e) {
      debugPrint('Erreur mise à jour données locales: $e');
      rethrow;
    }
  }

  /// Met à jour les produits depuis Google Sheets avec validation
  Future<void> _updateProductsFromSheets(List<Map<String, dynamic>> products) async {
    try {
      for (final productData in products) {
        try {
          // Valider les données du produit
          if (!_validateProductData(productData)) {
            debugPrint('Données produit invalides: $productData');
            continue;
          }
          
          final existingProduct = await _databaseService.getProductById(productData['ID']);
          
          if (existingProduct != null) {
            // Mettre à jour le produit existant
            await _databaseService.updateProduct(productData['ID'], productData);
          } else {
            // Ajouter un nouveau produit
            await _databaseService.addProduct(productData);
          }
        } catch (e) {
          debugPrint('Erreur mise à jour produit ${productData['ID']}: $e');
          // Continuer avec les autres produits
        }
      }
    } catch (e) {
      debugPrint('Erreur mise à jour produits: $e');
      rethrow;
    }
  }

  /// Met à jour les clients depuis Google Sheets avec validation
  Future<void> _updateClientsFromSheets(List<Map<String, dynamic>> clients) async {
    try {
      for (final clientData in clients) {
        try {
          // Valider les données du client
          if (!_validateClientData(clientData)) {
            debugPrint('Données client invalides: $clientData');
            continue;
          }
          
          final existingClient = await _databaseService.getClientById(clientData['ID']);
          
          if (existingClient != null) {
            // Mettre à jour le client existant
            await _databaseService.updateClient(clientData['ID'], clientData);
          } else {
            // Ajouter un nouveau client
            await _databaseService.addClient(clientData);
          }
        } catch (e) {
          debugPrint('Erreur mise à jour client ${clientData['ID']}: $e');
          // Continuer avec les autres clients
        }
      }
    } catch (e) {
      debugPrint('Erreur mise à jour clients: $e');
      rethrow;
    }
  }

  /// Met à jour les factures depuis Google Sheets avec validation
  Future<void> _updateInvoicesFromSheets(List<Map<String, dynamic>> invoices) async {
    try {
      for (final invoiceData in invoices) {
        try {
          // Valider les données de la facture
          if (!_validateInvoiceData(invoiceData)) {
            debugPrint('Données facture invalides: $invoiceData');
            continue;
          }
          
          final existingInvoice = await _databaseService.getInvoiceById(invoiceData['ID']);
          
          if (existingInvoice != null) {
            // Mettre à jour la facture existante
            await _databaseService.updateInvoice(invoiceData['ID'], invoiceData);
          } else {
            // Ajouter une nouvelle facture
            await _databaseService.addInvoice(invoiceData);
          }
        } catch (e) {
          debugPrint('Erreur mise à jour facture ${invoiceData['ID']}: $e');
          // Continuer avec les autres factures
        }
      }
    } catch (e) {
      debugPrint('Erreur mise à jour factures: $e');
      rethrow;
    }
  }

  /// Met à jour les articles de facture depuis Google Sheets avec validation
  Future<void> _updateInvoiceItemsFromSheets(List<Map<String, dynamic>> invoiceItems) async {
    try {
      for (final itemData in invoiceItems) {
        try {
          // Valider les données de l'article
          if (!_validateInvoiceItemData(itemData)) {
            debugPrint('Données article facture invalides: $itemData');
            continue;
          }
          
          final existingItem = await _databaseService.getInvoiceItemById(itemData['ID']);
          
          if (existingItem != null) {
            // Mettre à jour l'article existant
            await _databaseService.updateInvoiceItem(itemData['ID'], itemData);
          } else {
            // Ajouter un nouvel article
            await _databaseService.addInvoiceItem(itemData);
          }
        } catch (e) {
          debugPrint('Erreur mise à jour article ${itemData['ID']}: $e');
          // Continuer avec les autres articles
        }
      }
    } catch (e) {
      debugPrint('Erreur mise à jour articles facture: $e');
      rethrow;
    }
  }

  /// Récupère les données locales pour la synchronisation vers Google Sheets
  Future<Map<String, List<Map<String, dynamic>>>> _getLocalDataForSync() async {
    final data = <String, List<Map<String, dynamic>>>{};

    try {
      // Récupérer les produits modifiés récemment
      final products = await _databaseService.getRecentlyModifiedProducts(_lastSyncTime);
      if (products.isNotEmpty) {
        data['Produits'] = products.map((p) => _formatProductForSheets(p)).toList();
      }

      // Récupérer les clients modifiés récemment
      final clients = await _databaseService.getRecentlyModifiedClients(_lastSyncTime);
      if (clients.isNotEmpty) {
        data['Clients'] = clients.map((c) => _formatClientForSheets(c)).toList();
      }

      // Récupérer les factures modifiées récemment
      final invoices = await _databaseService.getRecentlyModifiedInvoices(_lastSyncTime);
      if (invoices.isNotEmpty) {
        data['Factures'] = invoices.map((i) => _formatInvoiceForSheets(i)).toList();
      }

      // Récupérer les articles de facture modifiés récemment
      final invoiceItems = await _databaseService.getRecentlyModifiedInvoiceItems(_lastSyncTime);
      if (invoiceItems.isNotEmpty) {
        data['Articles_Facture'] = invoiceItems.map((item) => _formatInvoiceItemForSheets(item)).toList();
      }
    } catch (e) {
      debugPrint('Erreur récupération données locales: $e');
    }

    return data;
  }

  /// Formate un produit pour Google Sheets
  Map<String, dynamic> _formatProductForSheets(Map<String, dynamic> product) {
    return {
      'ID': product['id']?.toString() ?? '',
      'Nom': product['name']?.toString() ?? '',
      'Description': product['description']?.toString() ?? '',
      'Prix': product['price']?.toString() ?? '0',
      'Stock': product['stock_quantity']?.toString() ?? '0',
      'Code-barres': product['barcode']?.toString() ?? '',
      'Catégorie': product['category']?.toString() ?? '',
      'Date création': product['created_at']?.toString() ?? '',
      'Date modification': product['updated_at']?.toString() ?? '',
    };
  }

  /// Formate un client pour Google Sheets
  Map<String, dynamic> _formatClientForSheets(Map<String, dynamic> client) {
    return {
      'ID': client['id']?.toString() ?? '',
      'Nom': client['name']?.toString() ?? '',
      'Prénom': client['first_name']?.toString() ?? '',
      'Email': client['email']?.toString() ?? '',
      'Téléphone': client['phone']?.toString() ?? '',
      'Adresse': client['address']?.toString() ?? '',
      'Date création': client['created_at']?.toString() ?? '',
      'Date modification': client['updated_at']?.toString() ?? '',
    };
  }

  /// Formate une facture pour Google Sheets
  Map<String, dynamic> _formatInvoiceForSheets(Map<String, dynamic> invoice) {
    return {
      'ID': invoice['id']?.toString() ?? '',
      'Numéro': invoice['invoice_number']?.toString() ?? '',
      'Client ID': invoice['client_id']?.toString() ?? '',
      'Date': invoice['date']?.toString() ?? '',
      'Total': invoice['total_amount']?.toString() ?? '0',
      'Statut': invoice['status']?.toString() ?? '',
      'Date création': invoice['created_at']?.toString() ?? '',
      'Date modification': invoice['updated_at']?.toString() ?? '',
    };
  }

  /// Formate un article de facture pour Google Sheets
  Map<String, dynamic> _formatInvoiceItemForSheets(Map<String, dynamic> item) {
    return {
      'ID': item['id']?.toString() ?? '',
      'Facture ID': item['invoice_id']?.toString() ?? '',
      'Produit ID': item['product_id']?.toString() ?? '',
      'Quantité': item['quantity']?.toString() ?? '0',
      'Prix unitaire': item['unit_price']?.toString() ?? '0',
      'Total': item['total_price']?.toString() ?? '0',
      'Date création': item['created_at']?.toString() ?? '',
    };
  }

  /// Valide les données d'un produit
  bool _validateProductData(Map<String, dynamic> data) {
    return data.containsKey('ID') && 
           data.containsKey('Nom') && 
           data['ID'] != null && 
           data['Nom'] != null &&
           data['Nom'].toString().trim().isNotEmpty;
  }

  /// Valide les données d'un client
  bool _validateClientData(Map<String, dynamic> data) {
    return data.containsKey('ID') && 
           data.containsKey('Nom') && 
           data['ID'] != null && 
           data['Nom'] != null &&
           data['Nom'].toString().trim().isNotEmpty;
  }

  /// Valide les données d'une facture
  bool _validateInvoiceData(Map<String, dynamic> data) {
    return data.containsKey('ID') && 
           data.containsKey('Numéro') && 
           data['ID'] != null && 
           data['Numéro'] != null &&
           data['Numéro'].toString().trim().isNotEmpty;
  }

  /// Valide les données d'un article de facture
  bool _validateInvoiceItemData(Map<String, dynamic> data) {
    return data.containsKey('ID') && 
           data.containsKey('Facture ID') && 
           data.containsKey('Produit ID') &&
           data['ID'] != null && 
           data['Facture ID'] != null &&
           data['Produit ID'] != null;
  }

  /// Met à jour les temps de synchronisation des feuilles
  void _updateSheetSyncTimes(List<String> sheetNames) {
    final now = DateTime.now();
    for (final sheetName in sheetNames) {
      _lastSheetSync[sheetName] = now;
    }
  }

  /// Obtient les statistiques de synchronisation
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isAutoSyncEnabled': _isAutoSyncEnabled,
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncInterval': _syncInterval.inMinutes,
      'successfulSyncs': _successfulSyncs,
      'failedSyncs': _failedSyncs,
      'totalSyncs': _successfulSyncs + _failedSyncs,
      'successRate': _successfulSyncs + _failedSyncs > 0 
          ? (_successfulSyncs / (_successfulSyncs + _failedSyncs) * 100).toStringAsFixed(1)
          : '0.0',
      'lastSheetSync': _lastSheetSync.map((key, value) => MapEntry(key, value.toIso8601String())),
      'error': _error,
    };
  }

  /// Obtient un rapport détaillé de l'état de synchronisation
  Map<String, dynamic> getSyncStatusReport() {
    return {
      'isRunning': _isRunning,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncInterval': _syncInterval.inMinutes,
      'hasInternetAccess': _connectivityService.hasInternetAccess,
      'isAuthenticated': _googleSheetsService.isAuthenticated,
      'lastError': _lastError,
      'consecutiveFailures': _consecutiveFailures,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'maxRetries': _maxRetries,
      'retryDelay': _retryDelay.inSeconds,
    };
  }

  /// Réinitialise les statistiques de synchronisation
  void resetStatistics() {
    _successfulSyncs = 0;
    _failedSyncs = 0;
    _lastSheetSync.clear();
    _setError(null);
    notifyListeners();
  }

  /// Définit une erreur
  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('AutoSyncService Error: $error');
    }
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}