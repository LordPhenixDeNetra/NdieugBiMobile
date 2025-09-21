enum DataSourceType {
  database,
  api,
  file,
  cloud,
  local,
  remote,
  cache;

  String toUpperCase() => name.toUpperCase();
  String toLowerCase() => name.toLowerCase();
}

enum DataSourceStatus {
  active,
  inactive,
  syncing,
  error,
  pending,
  connected,
  disconnected;

  String toUpperCase() => name.toUpperCase();
  String toLowerCase() => name.toLowerCase();
}

class DataSource {
  final String id;
  final String name;
  final DataSourceType type;
  final DataSourceStatus status;
  final String description;
  final String host;
  final int port;
  final DateTime? lastSync;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DataSource({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.description,
    required this.host,
    required this.port,
    this.lastSync,
    this.config = const {},
    required this.createdAt,
    this.updatedAt,
  });

  DataSource copyWith({
    String? id,
    String? name,
    DataSourceType? type,
    DataSourceStatus? status,
    String? description,
    String? host,
    int? port,
    DateTime? lastSync,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DataSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      host: host ?? this.host,
      port: port ?? this.port,
      lastSync: lastSync ?? this.lastSync,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'description': description,
      'host': host,
      'port': port,
      'lastSync': lastSync?.toIso8601String(),
      'config': config,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: DataSourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DataSourceType.local,
      ),
      status: DataSourceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DataSourceStatus.inactive,
      ),
      description: json['description'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 0,
      lastSync: json['lastSync'] != null 
          ? DateTime.parse(json['lastSync']) 
          : null,
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case DataSourceStatus.active:
        return 'Actif';
      case DataSourceStatus.inactive:
        return 'Inactif';
      case DataSourceStatus.syncing:
        return 'Synchronisation';
      case DataSourceStatus.error:
        return 'Erreur';
      case DataSourceStatus.pending:
        return 'En attente';
      case DataSourceStatus.connected:
        return 'Connecté';
      case DataSourceStatus.disconnected:
        return 'Déconnecté';
    }
  }

  String get typeText {
    switch (type) {
      case DataSourceType.database:
        return 'Base de données';
      case DataSourceType.api:
        return 'API';
      case DataSourceType.file:
        return 'Fichier';
      case DataSourceType.cloud:
        return 'Cloud';
      case DataSourceType.local:
        return 'Local';
      case DataSourceType.remote:
        return 'Distant';
      case DataSourceType.cache:
        return 'Cache';
    }
  }

  // Additional getters
  bool get database => type == DataSourceType.database;
  
  bool get isActive => status == DataSourceStatus.active || status == DataSourceStatus.connected;
}

class DataSourceRepository {
  final List<DataSource> _dataSources = [];

  List<DataSource> get dataSources => List.unmodifiable(_dataSources);

  List<DataSource> getDataSourcesByType(DataSourceType type) {
    return _dataSources.where((ds) => ds.type == type).toList();
  }

  List<DataSource> getDataSourcesByStatus(DataSourceStatus status) {
    return _dataSources.where((ds) => ds.status == status).toList();
  }

  DataSource? getDataSourceById(String id) {
    try {
      return _dataSources.firstWhere((ds) => ds.id == id);
    } catch (e) {
      return null;
    }
  }

  void addDataSource(DataSource dataSource) {
    _dataSources.add(dataSource);
  }

  void updateDataSource(DataSource dataSource) {
    final index = _dataSources.indexWhere((ds) => ds.id == dataSource.id);
    if (index != -1) {
      _dataSources[index] = dataSource;
    }
  }

  void removeDataSource(String id) {
    _dataSources.removeWhere((ds) => ds.id == id);
  }

  Future<void> loadDataSources() async {
    // Simulate loading data sources
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> testDataSource(String id) async {
    // Simulate testing data source connection
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<void> syncDataSource(String id) async {
    // Simulate syncing data source
    final dataSource = getDataSourceById(id);
    if (dataSource != null) {
      final updatedDataSource = dataSource.copyWith(
        status: DataSourceStatus.syncing,
        updatedAt: DateTime.now(),
      );
      updateDataSource(updatedDataSource);
      
      await Future.delayed(const Duration(seconds: 2));
      
      final syncedDataSource = updatedDataSource.copyWith(
        status: DataSourceStatus.active,
        lastSync: DateTime.now(),
      );
      updateDataSource(syncedDataSource);
    }
  }

  Future<void> refreshDataSources() async {
    // Simulate refreshing all data sources
    await Future.delayed(const Duration(milliseconds: 800));
  }
}