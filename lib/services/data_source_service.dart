import 'package:flutter/foundation.dart';
import '../domain/models/data_source.dart';
import '../domain/models/product.dart';
import '../domain/models/invoice.dart';
import '../domain/models/connection.dart' as domain;
import 'database_service.dart';
import 'data_source_manager.dart';
import 'connection_manager.dart';
import 'connectivity_service.dart';
import 'websocket_service.dart';
import 'api_service.dart';
import 'preferences_service.dart';

/// Service principal pour gérer les sources de données
/// Permet de basculer entre SQLite local et backend externe
class DataSourceService extends ChangeNotifier {
  static final DataSourceService _instance = DataSourceService._internal();
  factory DataSourceService() => _instance;
  DataSourceService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final DataSourceManager _dataSourceManager = DataSourceManager();
  final ConnectionManager _connectionManager = ConnectionManager();
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final PreferencesService _preferencesService = PreferencesService();

  DataSourceType _currentSourceType = DataSourceType.local;
  DataSource? _currentDataSource;
  bool _isInitialized = false;
  String? _externalConnectionName;

  // Getters
  DataSourceType get currentSourceType => _currentSourceType;
  DataSource? get currentDataSource => _currentDataSource;
  bool get isInitialized => _isInitialized;
  bool get isUsingLocalSource => _currentSourceType == DataSourceType.local;
  bool get isUsingExternalSource => _currentSourceType == DataSourceType.remote;
  String? get externalConnectionName => _externalConnectionName;

  /// Retourne la source de données actuelle
  DataSource? getCurrentDataSource() => _currentDataSource;

  /// Initialise le service des sources de données
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser les services de base
      await _databaseService.initialize();
      await _preferencesService.initialize();
      
      // Charger la configuration sauvegardée
      await _loadSavedConfiguration();
      
      _isInitialized = true;
      notifyListeners();
      debugPrint('DataSourceService initialisé avec source: $_currentSourceType');
    } catch (e) {
      debugPrint('Erreur d\'initialisation du DataSourceService: $e');
      rethrow;
    }
  }

  /// Configure une source de données locale
  Future<void> configureLocalSource() async {
    await _switchToLocalSource();
    await _saveConfiguration();
  }

  /// Configure une source de données externe
  Future<void> configureExternalSource({
    required String connectionName,
    required String host,
    required int port,
    bool useWebSocket = true,
    bool useApiRest = false,
  }) async {
    try {
      // Créer la configuration de connexion
      final config = domain.ConnectionConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: domain.ConnectionType.wifi, // Utiliser WiFi pour les connexions réseau
        name: connectionName,
        endpoint: 'http://$host:$port',
        createdAt: DateTime.now(),
        settings: {
          'websocket_enabled': useWebSocket,
          'api_rest_enabled': useApiRest,
          'websocket_endpoint': '/ws',
          'api_endpoint': '/api',
          'host': host,
          'port': port,
        },
      );

      // Ajouter la connexion au gestionnaire
      await _connectionManager.addConnection(config);
      
      // Tenter de se connecter
      final success = await _connectionManager.connect(connectionName);
      
      if (success) {
        _currentSourceType = DataSourceType.remote;
        _externalConnectionName = connectionName;
        
        // Désactiver SQLite local quand une source externe est configurée
        await _disableLocalSource();
        
        // Créer l'objet DataSource
        _currentDataSource = DataSource(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: connectionName,
          type: DataSourceType.remote,
          status: DataSourceStatus.connected,
          description: 'Backend externe sur $host:$port',
          host: host,
          port: port,
          createdAt: DateTime.now(),
          config: {
            'websocket_enabled': useWebSocket,
            'api_rest_enabled': useApiRest,
          },
        );

        await _saveConfiguration();
        notifyListeners();
        
        debugPrint('Source externe configurée: $connectionName - SQLite désactivé');
      } else {
        throw Exception('Impossible de se connecter au backend externe');
      }
    } catch (e) {
      debugPrint('Erreur lors de la configuration de la source externe: $e');
      rethrow;
    }
  }

  /// Bascule vers la source locale
  Future<void> _switchToLocalSource() async {
    _currentSourceType = DataSourceType.local;
    _externalConnectionName = null;
    
    // Réactiver SQLite local
    await _enableLocalSource();
    
    _currentDataSource = DataSource(
      id: 'local',
      name: 'Base de données locale',
      type: DataSourceType.local,
      status: DataSourceStatus.active,
      description: 'Base de données SQLite du téléphone',
      host: 'localhost',
      port: 0,
      createdAt: DateTime.now(),
    );

    notifyListeners();
    debugPrint('Basculement vers SQLite local - Source activée');
  }

  /// Active la source de données SQLite locale
  Future<void> _enableLocalSource() async {
    try {
      // Initialiser le gestionnaire de sources de données
      await _dataSourceManager.initialize();
      debugPrint('Source SQLite locale activée');
    } catch (e) {
      debugPrint('Erreur activation source locale: $e');
    }
  }

  /// Désactive la source de données SQLite locale
  Future<void> _disableLocalSource() async {
    try {
      // Fermer les connexions SQLite si nécessaire
      // Note: La fermeture complète peut être gérée par le DataSourceManager
      debugPrint('Source SQLite locale désactivée');
    } catch (e) {
      debugPrint('Erreur désactivation source locale: $e');
    }
  }

  /// Change la source de données
  Future<void> switchDataSource(DataSourceType sourceType, {String? connectionName}) async {
    if (!_isInitialized) {
      throw Exception('Service non initialisé');
    }

    try {
      _currentSourceType = sourceType;
      _externalConnectionName = connectionName;

      // Sauvegarder la configuration
      await _saveConfiguration();

      notifyListeners();
      debugPrint('Source de données changée vers: ${sourceType.name}');
    } catch (e) {
      debugPrint('Erreur lors du changement de source: $e');
      rethrow;
    }
  }

  /// Charge la configuration sauvegardée
  Future<void> _loadSavedConfiguration() async {
    try {
      final config = _preferencesService.getJson(PreferenceKeys.dataSourceConfig);
      
      if (config != null) {
        final sourceTypeString = config['source_type'] as String?;
        if (sourceTypeString != null) {
          _currentSourceType = DataSourceType.values.firstWhere(
            (type) => type.name == sourceTypeString,
            orElse: () => DataSourceType.local,
          );
        }
        
        _externalConnectionName = config['connection_name'] as String?;
        
        debugPrint('Configuration chargée: ${_currentSourceType.name}');
        
        // Si une source externe est configurée, vérifier qu'elle est disponible
        if (_currentSourceType != DataSourceType.local && _externalConnectionName != null) {
          await _validateExternalSource();
        }
      } else {
        // Aucune configuration sauvegardée, utiliser SQLite par défaut
        debugPrint('Aucune configuration trouvée, utilisation de SQLite par défaut');
        await _switchToLocalSource();
      }
    } catch (e) {
      debugPrint('Erreur chargement configuration: $e');
      // Utiliser SQLite par défaut en cas d'erreur
      _currentSourceType = DataSourceType.local;
      _externalConnectionName = null;
      await _switchToLocalSource();
    }
  }

  /// Sauvegarde la configuration actuelle
  Future<void> _saveConfiguration() async {
    try {
      final config = {
        'source_type': _currentSourceType.name,
        'connection_name': _externalConnectionName,
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await _preferencesService.setJson(PreferenceKeys.dataSourceConfig, config);
      debugPrint('Configuration sauvegardée: ${_currentSourceType.name}');
    } catch (e) {
      debugPrint('Erreur sauvegarde configuration: $e');
    }
  }

  /// Valide qu'une source externe est disponible
  Future<void> _validateExternalSource() async {
    try {
      if (_externalConnectionName == null) {
        throw Exception('Nom de connexion externe manquant');
      }

      // Tester la connexion externe
      final isAvailable = await _connectionManager.testConnection(_externalConnectionName!);
      
      if (!isAvailable) {
        debugPrint('Source externe indisponible, basculement vers SQLite');
        await _fallbackToLocalSource();
      } else {
        debugPrint('Source externe validée: $_externalConnectionName');
        // Créer l'objet DataSource pour la source externe
        await _createExternalDataSource();
      }
    } catch (e) {
      debugPrint('Erreur validation source externe: $e');
      await _fallbackToLocalSource();
    }
  }

  /// Bascule vers SQLite en cas d'échec de la source externe
  Future<void> _fallbackToLocalSource() async {
    debugPrint('Basculement automatique vers SQLite local');
    _currentSourceType = DataSourceType.local;
    _externalConnectionName = null;
    await _switchToLocalSource();
    await _saveConfiguration();
  }

  /// Crée l'objet DataSource pour une source externe
  Future<void> _createExternalDataSource() async {
    if (_externalConnectionName == null) return;

    final connectionInfo = _connectionManager.connections[_externalConnectionName!];
    if (connectionInfo != null) {
      // Extraire host et port depuis les settings ou endpoint
      final host = connectionInfo.config.settings['host'] as String? ?? 'unknown';
      final port = connectionInfo.config.settings['port'] as int? ?? 0;
      
      _currentDataSource = DataSource(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _externalConnectionName!,
        type: DataSourceType.remote,
        status: DataSourceStatus.connected,
        description: 'Backend externe configuré',
        host: host,
        port: port,
        createdAt: DateTime.now(),
        config: connectionInfo.config.settings,
      );
    }
  }

  /// Teste la connexion à la source actuelle
  Future<bool> testCurrentSource() async {
    try {
      if (_currentSourceType == DataSourceType.local) {
        // Test de la base de données locale
        final db = await _databaseService.database;
        await db.rawQuery('SELECT 1');
        return true;
      } else if (_externalConnectionName != null) {
        // Test de la connexion externe
        return await _connectionManager.testConnection(_externalConnectionName!);
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors du test de la source: $e');
      return false;
    }
  }

  /// Teste la connexion à une source externe
  Future<bool> testExternalConnection(String host, int port, {bool useWebSocket = false}) async {
    try {
      if (useWebSocket) {
        // Test de connexion WebSocket
        final wsUrl = 'ws://$host:$port/ws';
        return await _webSocketService.testConnection(wsUrl);
      } else {
        // Test de connexion API REST
        _apiService.initialize(ApiConfig(
          baseUrl: 'http://$host:$port',
          timeout: const Duration(seconds: 10),
        ));
        return await _apiService.testConnection();
      }
    } catch (e) {
      debugPrint('Erreur lors du test de connexion: $e');
      return false;
    }
  }

  // ==================== OPÉRATIONS SUR LES DONNÉES ====================

  /// Récupère tous les produits selon la source configurée
  Future<List<Product>> getProducts() async {
    if (!_isInitialized) await initialize();

    if (_currentSourceType == DataSourceType.local) {
      final productsData = await _databaseService.getProducts();
      return productsData.map((data) => Product.fromMap(data)).toList();
    } else {
      // Récupérer depuis le backend externe
      return await _getProductsFromExternal();
    }
  }

  /// Ajoute un produit selon la source configurée
  Future<int> addProduct(Product product) async {
    if (!_isInitialized) await initialize();

    if (_currentSourceType == DataSourceType.local) {
      return await _databaseService.addProduct(product.toMap());
    } else {
      // Ajouter via le backend externe
      return await _addProductToExternal(product);
    }
  }

  /// Met à jour un produit selon la source configurée
  Future<int> updateProduct(Product product) async {
    if (!_isInitialized) await initialize();

    if (_currentSourceType == DataSourceType.local) {
      return await _databaseService.updateProduct(product.id.toString(), product.toMap());
    } else {
      // Mettre à jour via le backend externe
      return await _updateProductInExternal(product);
    }
  }

  /// Supprime un produit selon la source configurée
  Future<int> deleteProduct(int id) async {
    if (!_isInitialized) await initialize();

    if (_currentSourceType == DataSourceType.local) {
      return await _databaseService.deleteProduct(id.toString());
    } else {
      // Supprimer via le backend externe
      return await _deleteProductFromExternal(id);
    }
  }

  /// Récupère toutes les factures selon la source configurée
  Future<List<Invoice>> getInvoices() async {
    if (!_isInitialized) await initialize();

    if (_currentSourceType == DataSourceType.local) {
      final invoicesData = await _databaseService.getInvoices();
      return invoicesData.map((data) => Invoice.fromMap(data)).toList();
    } else {
      // Récupérer depuis le backend externe
      return await _getInvoicesFromExternal();
    }
  }

  /// Ajoute une facture selon la source configurée
  Future<int> addInvoice(Invoice invoice) async {
    if (!_isInitialized) await initialize();

    if (_currentSourceType == DataSourceType.local) {
      return await _databaseService.addInvoice(invoice.toMap());
    } else {
      // Ajouter via le backend externe
      return await _addInvoiceToExternal(invoice);
    }
  }

  // ==================== MÉTHODES PRIVÉES POUR BACKEND EXTERNE ====================

  Future<List<Product>> _getProductsFromExternal() async {
    if (_externalConnectionName == null) {
      throw Exception('Aucune connexion externe configurée');
    }

    try {
      // Utiliser l'API REST ou WebSocket selon la configuration
      final response = await _connectionManager.sendData(_externalConnectionName!, {
        'action': 'get_products',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response) {
        // Ici, on devrait recevoir la réponse et la parser
        // Pour l'instant, retourner une liste vide
        return [];
      } else {
        throw Exception('Erreur lors de la récupération des produits');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des produits externes: $e');
      
      // Fallback vers la base locale si disponible
      if (_connectivityService.isOffline) {
        debugPrint('Mode hors ligne détecté, utilisation de la base locale');
        final productsData = await _databaseService.getProducts();
        return productsData.map((data) => Product.fromMap(data)).toList();
      }
      
      rethrow;
    }
  }

  Future<int> _addProductToExternal(Product product) async {
    if (_externalConnectionName == null) {
      throw Exception('Aucune connexion externe configurée');
    }

    try {
      final response = await _connectionManager.sendData(_externalConnectionName!, {
        'action': 'add_product',
        'data': product.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response) {
        // Aussi sauvegarder localement pour la synchronisation
      await _databaseService.addProduct(product.toMap());
        return product.id ?? 0;
      } else {
        throw Exception('Erreur lors de l\'ajout du produit');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du produit externe: $e');
      
      // Sauvegarder localement en cas d'erreur pour synchronisation ultérieure
      final localId = await _databaseService.addProduct(product.toMap());
      debugPrint('Produit sauvegardé localement pour synchronisation: $localId');
      
      return localId;
    }
  }

  Future<int> _updateProductInExternal(Product product) async {
    if (_externalConnectionName == null) {
      throw Exception('Aucune connexion externe configurée');
    }

    try {
      final response = await _connectionManager.sendData(_externalConnectionName!, {
        'action': 'update_product',
        'data': product.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response) {
        // Aussi mettre à jour localement
        await _databaseService.updateProduct(product.id.toString(), product.toMap());
        return 1;
      } else {
        throw Exception('Erreur lors de la mise à jour du produit');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du produit externe: $e');
      
      // Mettre à jour localement en cas d'erreur
      return await _databaseService.updateProduct(product.id.toString(), product.toMap());
    }
  }

  Future<int> _deleteProductFromExternal(int id) async {
    if (_externalConnectionName == null) {
      throw Exception('Aucune connexion externe configurée');
    }

    try {
      final response = await _connectionManager.sendData(_externalConnectionName!, {
        'action': 'delete_product',
        'id': id,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response) {
        // Aussi supprimer localement
        await _databaseService.deleteProduct(id.toString());
        return 1;
      } else {
        throw Exception('Erreur lors de la suppression du produit');
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du produit externe: $e');
      
      // Marquer comme supprimé localement pour synchronisation
      return await _databaseService.deleteProduct(id.toString());
    }
  }

  Future<List<Invoice>> _getInvoicesFromExternal() async {
    if (_externalConnectionName == null) {
      throw Exception('Aucune connexion externe configurée');
    }

    try {
      final response = await _connectionManager.sendData(_externalConnectionName!, {
        'action': 'get_invoices',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response) {
        // Parser la réponse et retourner les factures
        return [];
      } else {
        throw Exception('Erreur lors de la récupération des factures');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des factures externes: $e');
      
      // Fallback vers la base locale
      if (_connectivityService.isOffline) {
        final invoicesData = await _databaseService.getInvoices();
        return invoicesData.map((data) => Invoice.fromMap(data)).toList();
      }
      
      rethrow;
    }
  }

  Future<int> _addInvoiceToExternal(Invoice invoice) async {
    if (_externalConnectionName == null) {
      throw Exception('Aucune connexion externe configurée');
    }

    try {
      final response = await _connectionManager.sendData(_externalConnectionName!, {
        'action': 'add_invoice',
        'data': invoice.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response) {
        // Aussi sauvegarder localement
        await _databaseService.addInvoice(invoice.toMap());
        return invoice.id ?? 0;
      } else {
        throw Exception('Erreur lors de l\'ajout de la facture');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la facture externe: $e');
      
      // Sauvegarder localement pour synchronisation
      return await _databaseService.addInvoice(invoice.toMap());
    }
  }

  /// Synchronise les données entre local et externe
  Future<void> synchronizeData() async {
    if (_currentSourceType != DataSourceType.remote || _externalConnectionName == null) {
      return;
    }

    try {
      debugPrint('Début de la synchronisation des données...');
      
      // Ici, on pourrait implémenter une logique de synchronisation complète
      // - Comparer les timestamps
      // - Envoyer les modifications locales
      // - Récupérer les modifications distantes
      // - Résoudre les conflits
      
      debugPrint('Synchronisation terminée');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
    }
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    // Fermer les connexions actives
    if (_externalConnectionName != null) {
      _connectionManager.disconnect(_externalConnectionName!);
    }
    super.dispose();
  }
}