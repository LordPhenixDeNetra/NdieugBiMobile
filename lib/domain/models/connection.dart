enum ConnectionType {
  bluetooth,
  wifi,
  api,
  socket,
  local;

  String toUpperCase() => name.toUpperCase();
  String toLowerCase() => name.toLowerCase();
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  failed,
  unknown;

  String toUpperCase() => name.toUpperCase();
  String toLowerCase() => name.toLowerCase();
}

class ConnectionConfig {
  final String id;
  final String name;
  final String? description;
  final ConnectionType type;
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastConnected;
  
  // Propriétés spécifiques ajoutées
  final String? deviceId;
  final String? ssid;
  final String? password;
  final String? security;
  final String? endpoint;
  final String? apiKey;
  final int? signalStrength;

  const ConnectionConfig({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.settings,
    this.isActive = false,
    required this.createdAt,
    this.lastConnected,
    this.deviceId,
    this.ssid,
    this.password,
    this.security,
    this.endpoint,
    this.apiKey,
    this.signalStrength,
  });

  ConnectionConfig copyWith({
    String? id,
    String? name,
    String? description,
    ConnectionType? type,
    Map<String, dynamic>? settings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastConnected,
    String? deviceId,
    String? ssid,
    String? password,
    String? security,
    String? endpoint,
    String? apiKey,
    int? signalStrength,
  }) {
    return ConnectionConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastConnected: lastConnected ?? this.lastConnected,
      deviceId: deviceId ?? this.deviceId,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      security: security ?? this.security,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'settings': settings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
      'deviceId': deviceId,
      'ssid': ssid,
      'password': password,
      'security': security,
      'endpoint': endpoint,
      'apiKey': apiKey,
      'signalStrength': signalStrength,
    };
  }

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      type: ConnectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConnectionType.api,
      ),
      settings: json['settings'] ?? {},
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected']) 
          : null,
      deviceId: json['deviceId'],
      ssid: json['ssid'],
      password: json['password'],
      security: json['security'],
      endpoint: json['endpoint'],
      apiKey: json['apiKey'],
      signalStrength: json['signalStrength'],
    );
  }

  // Getter pour le statut
  ConnectionStatus get status {
    if (isActive) {
      return lastConnected != null && 
             DateTime.now().difference(lastConnected!).inMinutes < 5
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected;
    }
    return ConnectionStatus.disconnected;
  }
}

class Connection {
  final String id;
  final String name;
  final ConnectionType type;
  final ConnectionStatus status;
  final String description;
  final ConnectionConfig config;
  final DateTime createdAt;
  final DateTime? lastConnected;
  final String? signalStrength;

  const Connection({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.description,
    required this.config,
    required this.createdAt,
    this.lastConnected,
    this.signalStrength,
  });

  // Getters manquants ajoutés
  bool get isConnected => status == ConnectionStatus.connected;
  
  String? get address {
    switch (type) {
      case ConnectionType.bluetooth:
        return config.deviceId;
      case ConnectionType.wifi:
        return config.ssid;
      case ConnectionType.api:
        return config.endpoint;
      case ConnectionType.socket:
        return config.endpoint;
      case ConnectionType.local:
        return 'localhost';
    }
  }
  
  String? get ssid => config.ssid;
  
  String? get endpoint => config.endpoint;
  
  DateTime? get lastPing => lastConnected;
  
  bool get isActive => status == ConnectionStatus.connected || status == ConnectionStatus.connecting;

  // Additional missing getters
  String? get deviceId => config.deviceId;
  String? get password => config.password;
  String? get security => config.security;
  String? get apiKey => config.apiKey;
  Map<String, dynamic>? get settings => config.settings;

  Connection copyWith({
    String? id,
    String? name,
    ConnectionType? type,
    ConnectionStatus? status,
    String? description,
    ConnectionConfig? config,
    DateTime? createdAt,
    DateTime? lastConnected,
    String? signalStrength,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      lastConnected: lastConnected ?? this.lastConnected,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'description': description,
      'config': config.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
      'signalStrength': signalStrength,
    };
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: ConnectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConnectionType.local,
      ),
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.unknown,
      ),
      description: json['description'] ?? '',
      config: ConnectionConfig.fromJson(json['config'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected']) 
          : null,
      signalStrength: json['signalStrength'],
    );
  }
}

class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  final List<Connection> _connections = [];
  final List<ConnectionConfig> _configs = [];

  List<Connection> get connections => List.unmodifiable(_connections);
  List<ConnectionConfig> get configs => List.unmodifiable(_configs);

  Future<void> initialize() async {
    // Initialisation des connexions
  }

  Future<Connection> createConnection(ConnectionConfig config) async {
    final connection = Connection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: config.name,
      type: config.type,
      description: config.description ?? '',
      config: config,
      status: ConnectionStatus.disconnected,
      createdAt: DateTime.now(),
    );
    
    _connections.add(connection);
    return connection;
  }

  Future<bool> testConnection(ConnectionConfig config) async {
    // Simulation du test de connexion
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<void> deleteConnection(String id) async {
    _connections.removeWhere((conn) => conn.id == id);
    _configs.removeWhere((config) => config.id == id);
  }

  Future<void> updateConnection(Connection connection) async {
    final index = _connections.indexWhere((conn) => conn.id == connection.id);
    if (index != -1) {
      _connections[index] = connection;
    }
  }

  // Méthodes manquantes ajoutées
  Future<List<String>> scanWiFiNetworks() async {
    // Simulation du scan WiFi
    await Future.delayed(const Duration(seconds: 2));
    return [
      'WiFi-Network-1',
      'WiFi-Network-2',
      'WiFi-Network-3',
      'Home-WiFi',
      'Office-WiFi',
    ];
  }

  List<Connection> getConnectionsByType(ConnectionType type) {
    return _connections.where((conn) => conn.type == type).toList();
  }

  Future<void> connectToWiFi(String ssid, String password) async {
    // Simulation de connexion WiFi
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> disconnectFromWiFi() async {
    // Simulation de déconnexion WiFi
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<bool> isConnectedToWiFi() async {
    // Simulation de vérification de connexion WiFi
    return true;
  }

  Future<String?> getCurrentWiFiSSID() async {
    // Simulation de récupération du SSID actuel
    return 'Current-WiFi-Network';
  }

  Future<void> refreshConnections() async {
    // Simulation de rafraîchissement des connexions
    await Future.delayed(const Duration(seconds: 1));
    // Mettre à jour le statut de toutes les connexions
    for (int i = 0; i < _connections.length; i++) {
      final connection = _connections[i];
      // Simuler une vérification de statut
      final isConnected = await testConnection(connection.config);
      _connections[i] = connection.copyWith(
        status: isConnected ? ConnectionStatus.connected : ConnectionStatus.disconnected,
        lastConnected: isConnected ? DateTime.now() : connection.lastConnected,
      );
    }
  }
}