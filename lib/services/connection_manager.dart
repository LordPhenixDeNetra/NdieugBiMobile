import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as flutter_bluetooth_serial;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import '../domain/models/connection.dart' as domain;

class NetworkInfo {
  final String? wifiName;
  final String? wifiBSSID;
  final String? wifiIP;
  final String? wifiIPv6;
  final String? wifiSubmask;
  final String? wifiBroadcast;
  final String? wifiGateway;

  NetworkInfo({
    this.wifiName,
    this.wifiBSSID,
    this.wifiIP,
    this.wifiIPv6,
    this.wifiSubmask,
    this.wifiBroadcast,
    this.wifiGateway,
  });
}

class BluetoothConnection {
  final BluetoothDevice device;
  BluetoothConnection? connection;
  bool isConnected;

  BluetoothConnection({
    required this.device,
    this.connection,
    this.isConnected = false,
  });
}

class BluetoothDevice {
  final String name;
  final String address;
  final bool isConnected;

  BluetoothDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });
}

/// Configuration d'une connexion
class ServiceConnectionConfig {
  final domain.ConnectionType type;
  final String name;
  final String? address;
  final int? port;
  final Map<String, String>? headers;
  final Map<String, dynamic>? credentials;
  final Duration timeout;
  final bool autoReconnect;
  final Map<String, dynamic>? metadata;
  final String? endpoint;
  final String? apiKey;
  final Map<String, dynamic> settings;

  const ServiceConnectionConfig({
    required this.type,
    required this.name,
    this.address,
    this.port,
    this.headers,
    this.credentials,
    this.timeout = const Duration(seconds: 30),
    this.autoReconnect = true,
    this.metadata,
    this.endpoint,
    this.apiKey,
    this.settings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'name': name,
      'address': address,
      'port': port,
      'headers': headers != null ? jsonEncode(headers) : null,
      'credentials': credentials != null ? jsonEncode(credentials) : null,
      'timeout_seconds': timeout.inSeconds,
      'auto_reconnect': autoReconnect ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'endpoint': endpoint,
      'api_key': apiKey,
      'settings': jsonEncode(settings),
    };
  }

  factory ServiceConnectionConfig.fromMap(Map<String, dynamic> map) {
    return ServiceConnectionConfig(
      type: domain.ConnectionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => domain.ConnectionType.wifi,
      ),
      name: map['name'] as String,
      address: map['address'] as String?,
      port: map['port'] as int?,
      headers: map['headers'] != null 
          ? Map<String, String>.from(jsonDecode(map['headers']))
          : null,
      credentials: map['credentials'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['credentials']))
          : null,
      timeout: Duration(seconds: map['timeout_seconds'] as int? ?? 30),
      autoReconnect: (map['auto_reconnect'] as int?) == 1,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata']))
          : null,
      endpoint: map['endpoint'] as String?,
      apiKey: map['api_key'] as String?,
      settings: map['settings'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['settings']))
          : {},
    );
  }
}

/// Informations sur une connexion active
class ConnectionInfo {
  final ServiceConnectionConfig config;  // Utilise la classe locale ServiceConnectionConfig
  final domain.ConnectionStatus status;
  final DateTime? connectedAt;
  final DateTime? lastActivity;
  final String? error;
  final Map<String, dynamic>? details;

  const ConnectionInfo({
    required this.config,
    required this.status,
    this.connectedAt,
    this.lastActivity,
    this.error,
    this.details,
  });

  ConnectionInfo copyWith({
    ServiceConnectionConfig? config,  // Utilise la classe locale ServiceConnectionConfig
    domain.ConnectionStatus? status,
    DateTime? connectedAt,
    DateTime? lastActivity,
    String? error,
    Map<String, dynamic>? details,
  }) {
    return ConnectionInfo(
      config: config ?? this.config,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      error: error ?? this.error,
      details: details ?? this.details,
    );
  }
}

/// Gestionnaire centralisé des connexions
class ConnectionManager extends ChangeNotifier {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  final DatabaseService _databaseService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final info = NetworkInfo();

  final Map<String, ConnectionInfo> _connections = {};
  final Map<String, dynamic> _activeConnections = {};
  final Map<String, Timer> _reconnectTimers = {};
  
  bool _isInitialized = false;
  bool _isScanning = false;

  // Getters
  Map<String, ConnectionInfo> get connections => Map.unmodifiable(_connections);
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;

  /// Initialise le gestionnaire de connexions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _createConnectionsTable();
      await _loadConnections();
      await _initializeBluetoothIfAvailable();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'initialisation du ConnectionManager: $e');
      rethrow;
    }
  }

  /// Crée la table des connexions
  Future<void> _createConnectionsTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL UNIQUE,
        address TEXT,
        port INTEGER,
        headers TEXT,
        credentials TEXT,
        timeout_seconds INTEGER NOT NULL DEFAULT 30,
        auto_reconnect INTEGER NOT NULL DEFAULT 1,
        metadata TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX IF NOT EXISTS idx_connections_type ON connections (type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_connections_name ON connections (name)');
  }

  /// Charge les connexions depuis la base
  Future<void> _loadConnections() async {
    final db = await _databaseService.database;
    final results = await db.query('connections');
    
    _connections.clear();
    for (final result in results) {
      final config = domain.ConnectionConfig.fromJson(result);
      _connections[config.name] = ConnectionInfo(
        config: _convertToServiceConfig(config),
        status: domain.ConnectionStatus.disconnected,
      );
    }
  }

  /// Initialise Bluetooth si disponible
  Future<void> _initializeBluetoothIfAvailable() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final bluetoothState = await flutter_bluetooth_serial.FlutterBluetoothSerial.instance.state;
        debugPrint('État Bluetooth: $bluetoothState');
      }
    } catch (e) {
      debugPrint('Bluetooth non disponible: $e');
    }
  }

  /// Ajoute une nouvelle connexion
  Future<void> addConnection(domain.ConnectionConfig config) async {
    try {
      final db = await _databaseService.database;
      await db.insert('connections', {
        ...config.toJson(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _connections[config.name] = ConnectionInfo(
        config: _convertToServiceConfig(config),
        status: domain.ConnectionStatus.disconnected,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la connexion: $e');
      rethrow;
    }
  }

  /// Met à jour une connexion
  Future<void> updateConnection(String name, domain.ConnectionConfig config) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'connections',
        {
          ...config.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'name = ?',
        whereArgs: [name],
      );

      if (_connections.containsKey(name)) {
        _connections[name] = ConnectionInfo(
          config: _convertToServiceConfig(config),
          status: _connections[name]!.status,
          connectedAt: _connections[name]!.connectedAt,
          lastActivity: _connections[name]!.lastActivity,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la connexion: $e');
      rethrow;
    }
  }

  /// Supprime une connexion
  Future<void> removeConnection(String name) async {
    try {
      // Déconnecter d'abord si connecté
      if (_connections[name]?.status == domain.ConnectionStatus.connected) {
        await disconnect(name);
      }

      final db = await _databaseService.database;
      await db.delete('connections', where: 'name = ?', whereArgs: [name]);

      _connections.remove(name);
      _activeConnections.remove(name);
      _reconnectTimers[name]?.cancel();
      _reconnectTimers.remove(name);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la connexion: $e');
      rethrow;
    }
  }

  /// Se connecte à un terminal
  Future<bool> connect(String name) async {
    final connectionInfo = _connections[name];
    if (connectionInfo == null) {
      throw Exception('Connexion non trouvée: $name');
    }

    if (connectionInfo.status == domain.ConnectionStatus.connected) {
      return true;
    }

    _updateConnectionStatus(name, domain.ConnectionStatus.connecting);

    try {
      final config = connectionInfo.config;
      bool success = false;

      switch (config.type) {
        case domain.ConnectionType.bluetooth:
          success = await _connectBluetooth(name, config);
          break;
        case domain.ConnectionType.wifi:
          success = await _connectWifi(name, config);
          break;
        case domain.ConnectionType.api:
          success = await _connectApi(name, config);
          break;
        case domain.ConnectionType.socket:
          success = await _connectSocket(name, config);
          break;
        case domain.ConnectionType.local:
          // Local connections - implement as needed
          success = false;
          break;
      }

      if (success) {
        _updateConnectionStatus(name, domain.ConnectionStatus.connected, connectedAt: DateTime.now());
        
        // Démarrer la reconnexion automatique si configurée
      if (config.settings['autoReconnect'] == true) {
        _startAutoReconnect(name);
      }
      } else {
        _updateConnectionStatus(name, domain.ConnectionStatus.failed, error: 'Échec de connexion');
      }

      return success;
    } catch (e) {
      _updateConnectionStatus(name, domain.ConnectionStatus.failed, error: e.toString());
      return false;
    }
  }

  /// Se déconnecte d'un terminal
  Future<void> disconnect(String name) async {
    final connectionInfo = _connections[name];
    if (connectionInfo == null) return;

    try {
      // Arrêter la reconnexion automatique
      _reconnectTimers[name]?.cancel();
      _reconnectTimers.remove(name);

      // Fermer la connexion selon le type
      final activeConnection = _activeConnections[name];
      if (activeConnection != null) {
        switch (connectionInfo.config.type) {
          case domain.ConnectionType.bluetooth:
            if (activeConnection is flutter_bluetooth_serial.BluetoothConnection) {
              // Fermer la connexion flutter_bluetooth_serial
              await activeConnection.close();
            }
            break;
          case domain.ConnectionType.wifi:
            if (activeConnection is WebSocketChannel) {
              await activeConnection.sink.close();
            }
            break;
          case domain.ConnectionType.socket:
            if (activeConnection is Socket) {
              await activeConnection.close();
            }
            break;
          case domain.ConnectionType.api:
            // Pas de connexion persistante pour API
            break;
          case domain.ConnectionType.local:
            // Local connections - handle disconnection as needed
            break;
        }
      }

      _activeConnections.remove(name);
      _updateConnectionStatus(name, domain.ConnectionStatus.disconnected);
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      _updateConnectionStatus(name, domain.ConnectionStatus.failed, error: e.toString());
    }
  }

  /// Connexion Bluetooth
  Future<bool> _connectBluetooth(String name, ServiceConnectionConfig config) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Bluetooth non supporté sur le web');
      }

      if (config.settings['deviceId'] == null) {
          throw ArgumentError('Device ID requis pour la connexion Bluetooth');
        }

        final connection = await flutter_bluetooth_serial.BluetoothConnection.toAddress(config.settings['deviceId']!);
      _activeConnections[name] = connection;

      // Écouter les déconnexions
      connection.input!.listen(
        (data) {
          _updateConnectionActivity(name);
        },
        onDone: () {
          _handleConnectionLost(name);
        },
        onError: (error) {
           _updateConnectionStatus(name, domain.ConnectionStatus.failed, error: error.toString());
         },
      );

      return connection.isConnected;
    } catch (e) {
      debugPrint('Erreur de connexion Bluetooth: $e');
      return false;
    }
  }

  /// Connexion WiFi (WebSocket)
  Future<bool> _connectWifi(String name, ServiceConnectionConfig config) async {
    try {
      if (config.endpoint == null) {
        throw ArgumentError('Endpoint requis pour la connexion WiFi');
      }

      final port = config.settings['port'] ?? 8080;
      final uri = Uri.parse('ws://${config.endpoint}:$port');
      final channel = WebSocketChannel.connect(uri);
      
      final timeout = Duration(seconds: config.settings['timeout'] ?? 30);
      await channel.ready.timeout(timeout);
      _activeConnections[name] = channel;

      // Écouter les messages et déconnexions
      channel.stream.listen(
        (data) {
          _updateConnectionActivity(name);
        },
        onDone: () {
          _handleConnectionLost(name);
        },
        onError: (error) {
           _updateConnectionStatus(name, domain.ConnectionStatus.failed, error: error.toString());
         },
      );

      return true;
    } catch (e) {
      debugPrint('Erreur de connexion WiFi: $e');
      return false;
    }
  }

  /// Connexion API REST
  Future<bool> _connectApi(String name, ServiceConnectionConfig config) async {
    try {
      if (!_connectivityService.isOnline) {
        throw Exception('Connexion Internet requise');
      }

      if (config.endpoint == null) {
        throw Exception('Endpoint API requis');
      }

      final timeout = Duration(seconds: config.settings['timeout'] ?? 30);
      final headers = Map<String, String>.from(config.settings['headers'] ?? {});
      
      // Test de connexion avec un ping
      final response = await http.get(
        Uri.parse('${config.endpoint}/health'),
        headers: headers,
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur de connexion API: $e');
      return false;
    }
  }

  /// Connexion Socket réseau
  Future<bool> _connectSocket(String name, ServiceConnectionConfig config) async {
    try {
      if (config.endpoint == null || config.settings['port'] == null) {
        throw Exception('Endpoint et port requis pour socket');
      }

      final socket = await Socket.connect(
        config.endpoint!,
        config.settings['port']!,
        timeout: Duration(seconds: config.settings['timeout'] ?? 30),
      );

      _activeConnections[name] = socket;

      // Écouter les données et déconnexions
      socket.listen(
        (data) {
          _updateConnectionActivity(name);
        },
        onDone: () {
          _handleConnectionLost(name);
        },
        onError: (error) {
           _updateConnectionStatus(name, domain.ConnectionStatus.failed, error: error.toString());
         },
      );

      return true;
    } catch (e) {
      debugPrint('Erreur de connexion Socket: $e');
      return false;
    }
  }

  /// Met à jour le statut d'une connexion
  void _updateConnectionStatus(
    String name,
    domain.ConnectionStatus status, {
    DateTime? connectedAt,
    String? error,
  }) {
    final current = _connections[name];
    if (current == null) return;

    _connections[name] = ConnectionInfo(
      config: current.config,
      status: status,
      connectedAt: connectedAt ?? current.connectedAt,
      lastActivity: current.lastActivity,
      error: error,
    );

    notifyListeners();
  }

  /// Met à jour l'activité d'une connexion
  void _updateConnectionActivity(String name) {
    final current = _connections[name];
    if (current == null) return;

    _connections[name] = ConnectionInfo(
      config: current.config,
      status: current.status,
      connectedAt: current.connectedAt,
      lastActivity: DateTime.now(),
      error: current.error,
    );
  }

  /// Gère la perte de connexion
  void _handleConnectionLost(String name) {
    _updateConnectionStatus(name, domain.ConnectionStatus.disconnected);
    _activeConnections.remove(name);

    final config = _connections[name]?.config;
    if (config?.settings['autoReconnect'] == true) {
      _scheduleReconnect(name);
    }
  }

  /// Démarre la reconnexion automatique
  void _startAutoReconnect(String name) {
    _reconnectTimers[name]?.cancel();
    _reconnectTimers[name] = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(name),
    );
  }

  /// Vérifie l'état d'une connexion
  Future<void> _checkConnection(String name) async {
    final info = _connections[name];
    if (info == null || info.status != domain.ConnectionStatus.connected) {
      return;
    }

    // Vérifier si la connexion est toujours active
    final lastActivity = info.lastActivity ?? info.connectedAt;
    if (lastActivity != null) {
      final timeSinceActivity = DateTime.now().difference(lastActivity);
      if (timeSinceActivity.inMinutes > 5) {
        // Pas d'activité depuis 5 minutes, reconnecter
        _scheduleReconnect(name);
      }
    }
  }

  /// Programme une reconnexion
  void _scheduleReconnect(String name) {
    _reconnectTimers[name]?.cancel();
    _reconnectTimers[name] = Timer(
      const Duration(seconds: 5),
      () => connect(name),
    );
  }

  /// Scanne les appareils Bluetooth disponibles
  Future<List<BluetoothDevice>> scanBluetoothDevices() async {
    if (kIsWeb) {
      throw Exception('Bluetooth non supporté sur le web');
    }

    _isScanning = true;
    notifyListeners();

    try {
      final bondedDevices = await flutter_bluetooth_serial.FlutterBluetoothSerial.instance.getBondedDevices();
      
      return bondedDevices.map((device) => BluetoothDevice(
        name: device.name ?? 'Unknown',
        address: device.address,
        isConnected: device.isConnected,
      )).toList();
    } catch (e) {
      debugPrint('Erreur lors du scan Bluetooth: $e');
      return [];
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Obtient les informations réseau WiFi
  Future<Map<String, String?>> getWifiInfo() async {
    try {
      // Retourner des valeurs par défaut car network_info_plus n'est plus utilisé
      return {
        'ssid': 'Non disponible',
        'bssid': 'Non disponible',
        'ip': 'Non disponible',
        'gateway': 'Non disponible',
        'subnet': 'Non disponible',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos WiFi: $e');
      return {};
    }
  }

  /// Envoie des données via une connexion
  Future<bool> sendData(String name, dynamic data) async {
    final activeConnection = _activeConnections[name];
    if (activeConnection == null) {
      throw Exception('Connexion non active: $name');
    }

    try {
      final connectionInfo = _connections[name]!;
      switch (connectionInfo.config.type) {
         case domain.ConnectionType.bluetooth:
           if (activeConnection is flutter_bluetooth_serial.BluetoothConnection) {
             // Utiliser directement la connexion flutter_bluetooth_serial
             activeConnection.output.add(utf8.encode(jsonEncode(data)));
             await activeConnection.output.allSent;
           }
           break;
         case domain.ConnectionType.wifi:
           if (activeConnection is WebSocketChannel) {
             activeConnection.sink.add(jsonEncode(data));
           }
           break;
         case domain.ConnectionType.socket:
           if (activeConnection is Socket) {
             activeConnection.add(utf8.encode(jsonEncode(data)));
             await activeConnection.flush();
           }
           break;
         case domain.ConnectionType.api:
           // Envoyer via HTTP POST
           final config = connectionInfo.config;
           final headers = Map<String, String>.from(config.settings['headers'] ?? {});
           await http.post(
             Uri.parse('${config.endpoint}/data'),
             headers: {
               'Content-Type': 'application/json',
               ...headers,
             },
             body: jsonEncode(data),
           );
           break;
         case domain.ConnectionType.local:
           // Local connections - handle as needed
           throw Exception('Local connections not yet implemented');
       }

      _updateConnectionActivity(name);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de données: $e');
      return false;
    }
  }

  /// Obtient les statistiques des connexions
  Map<String, dynamic> getConnectionStatistics() {
    final totalConnections = _connections.length;
    final activeConnections = _connections.values
        .where((info) => info.status == domain.ConnectionStatus.connected)
        .length;
    final errorConnections = _connections.values
        .where((info) => info.status == domain.ConnectionStatus.failed)
        .length;

    return {
      'totalConnections': totalConnections,
      'activeConnections': activeConnections,
      'errorConnections': errorConnections,
      'connectionTypes': _connections.values
          .map((info) => info.config.type.toString())
          .toSet()
          .toList(),
    };
  }

  /// Scanne les réseaux WiFi disponibles
  Future<List<Map<String, dynamic>>> scanWiFiNetworks() async {
    try {
      _isScanning = true;
      notifyListeners();
      
      // Simulation du scan WiFi - remplacer par une vraie implémentation
      await Future.delayed(const Duration(seconds: 2));
      
      final networks = <Map<String, dynamic>>[
        {'ssid': 'WiFi-Network-1', 'signalStrength': -45, 'security': 'WPA2'},
        {'ssid': 'WiFi-Network-2', 'signalStrength': -60, 'security': 'WPA3'},
        {'ssid': 'WiFi-Network-3', 'signalStrength': -75, 'security': 'Open'},
      ];
      
      return networks;
    } catch (e) {
      debugPrint('Erreur lors du scan WiFi: $e');
      return [];
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Obtient les connexions par type
  List<ConnectionInfo> getConnectionsByType(domain.ConnectionType type) {
    return _connections.values
        .where((info) => info.config.type == type)
        .toList();
  }

  /// Rafraîchit toutes les connexions
  Future<void> refreshConnections() async {
    try {
      await _loadConnections();
      
      // Teste toutes les connexions actives
      final activeNames = _connections.keys.toList();
      for (final name in activeNames) {
        final info = _connections[name];
        if (info != null && info.status == domain.ConnectionStatus.connected) {
          await testConnection(name);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement des connexions: $e');
    }
  }

  /// Teste les connexions API
  Future<bool> testApiConnections() async {
    try {
      final apiConnections = getConnectionsByType(domain.ConnectionType.api);
      bool allSuccessful = true;
      
      for (final connection in apiConnections) {
        final result = await testConnection(connection.config.name);
        if (!result) {
          allSuccessful = false;
        }
      }
      
      return allSuccessful;
    } catch (e) {
      debugPrint('Erreur lors du test des connexions API: $e');
      return false;
    }
  }

  /// Teste une connexion spécifique
  Future<bool> testConnection(String name) async {
    final info = _connections[name];
    if (info == null) return false;

    try {
      switch (info.config.type) {
        case domain.ConnectionType.api:
          // Test de connexion API
          final client = http.Client();
          final response = await client.get(
            Uri.parse(info.config.endpoint ?? 'http://localhost:8080/api/health'),
            headers: info.config.apiKey != null 
                ? {'Authorization': 'Bearer ${info.config.apiKey}'}
                : null,
          ).timeout(const Duration(seconds: 10));
          
          final isConnected = response.statusCode == 200;
          _updateConnectionStatus(name, isConnected 
              ? domain.ConnectionStatus.connected 
              : domain.ConnectionStatus.failed);
          return isConnected;

        case domain.ConnectionType.wifi:
          // Test de connexion WiFi
          final connectivity = await Connectivity().checkConnectivity();
          final isConnected = connectivity == ConnectivityResult.wifi;
          _updateConnectionStatus(name, isConnected 
              ? domain.ConnectionStatus.connected 
              : domain.ConnectionStatus.failed);
          return isConnected;

        case domain.ConnectionType.bluetooth:
          // Test de connexion Bluetooth
          final isConnected = _activeConnections.containsKey(name);
          _updateConnectionStatus(name, isConnected 
              ? domain.ConnectionStatus.connected 
              : domain.ConnectionStatus.failed);
          return isConnected;

        case domain.ConnectionType.socket:
          // Test de connexion Socket
          try {
            final socket = await Socket.connect(
              info.config.endpoint ?? 'localhost',
              int.parse(info.config.settings['port']?.toString() ?? '8080'),
              timeout: const Duration(seconds: 5),
            );
            socket.destroy();
            _updateConnectionStatus(name, domain.ConnectionStatus.connected);
            return true;
          } catch (e) {
            _updateConnectionStatus(name, domain.ConnectionStatus.failed);
            return false;
          }

        case domain.ConnectionType.local:
          // Test de connexion locale
          _updateConnectionStatus(name, domain.ConnectionStatus.connected);
          return true;
      }
    } catch (e) {
      debugPrint('Erreur lors du test de connexion $name: $e');
      _updateConnectionStatus(name, domain.ConnectionStatus.failed);
      return false;
    }
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    for (final timer in _reconnectTimers.values) {
      timer.cancel();
    }
    _reconnectTimers.clear();
    
    for (final name in _activeConnections.keys.toList()) {
      disconnect(name);
    }
    
    _connections.clear();
    _activeConnections.clear();
    super.dispose();
  }

  /// Convertit un domain.ConnectionConfig en ServiceConnectionConfig
  ServiceConnectionConfig _convertToServiceConfig(domain.ConnectionConfig domainConfig) {
    final settings = Map<String, dynamic>.from(domainConfig.settings);
    
    // Ajouter les propriétés spécifiques aux settings
    if (domainConfig.deviceId != null) {
      settings['deviceId'] = domainConfig.deviceId;
    }
    if (domainConfig.ssid != null) {
      settings['ssid'] = domainConfig.ssid;
    }
    if (domainConfig.password != null) {
      settings['password'] = domainConfig.password;
    }
    if (domainConfig.security != null) {
      settings['security'] = domainConfig.security;
    }
    
    return ServiceConnectionConfig(
      type: domainConfig.type,
      name: domainConfig.name,
      address: domainConfig.endpoint,
      port: null,
      headers: null,
      credentials: null,
      timeout: const Duration(seconds: 30),
      autoReconnect: true,
      metadata: null,
      endpoint: domainConfig.endpoint,
      apiKey: domainConfig.apiKey,
      settings: settings,
    );
  }
}