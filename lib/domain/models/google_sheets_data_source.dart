import 'data_source.dart';

/// Classe spécialisée pour les sources de données Google Sheets
class GoogleSheetsDataSource extends DataSource {
  final String spreadsheetId;
  final String? sheetName;
  final String? range;
  final bool hasHeaders;
  final Map<String, String>? columnMapping;

  GoogleSheetsDataSource({
    required super.id,
    required super.name,
    required super.description,
    required this.spreadsheetId,
    this.sheetName,
    this.range,
    this.hasHeaders = true,
    this.columnMapping,
    super.status = DataSourceStatus.active,
    super.host = 'sheets.googleapis.com',
    super.port = 443,
    super.lastSync,
    super.config = const {},
    super.syncInterval,
    DateTime? createdAt,
  }) : super(
         type: DataSourceType.cloud,
         createdAt: createdAt ?? DateTime.now(),
       );

  /// Crée une instance depuis un Map (pour la sérialisation)
  factory GoogleSheetsDataSource.fromMap(Map<String, dynamic> map) {
    return GoogleSheetsDataSource(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      spreadsheetId: map['spreadsheetId'] as String,
      sheetName: map['sheetName'] as String?,
      range: map['range'] as String?,
      hasHeaders: map['hasHeaders'] as bool? ?? true,
      columnMapping: map['columnMapping'] != null 
          ? Map<String, String>.from(map['columnMapping'] as Map)
          : null,
      status: map['status'] != null 
          ? DataSourceStatus.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => DataSourceStatus.active,
            )
          : DataSourceStatus.active,
      lastSync: map['lastSync'] != null 
          ? DateTime.parse(map['lastSync'] as String)
          : null,
      syncInterval: map['syncInterval'] != null
          ? Duration(minutes: map['syncInterval'] as int)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convertit l'instance en Map (pour la sérialisation)
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'spreadsheetId': spreadsheetId,
      'sheetName': sheetName,
      'range': range,
      'hasHeaders': hasHeaders,
      'columnMapping': columnMapping,
    });
    return map;
  }

  /// Crée une copie avec des modifications
  @override
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
    Duration? syncInterval,
  }) {
    return GoogleSheetsDataSource(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
      range: range,
      hasHeaders: hasHeaders,
      columnMapping: columnMapping,
      status: status ?? this.status,
      host: host ?? this.host,
      port: port ?? this.port,
      lastSync: lastSync ?? this.lastSync,
      config: config ?? this.config,
      syncInterval: syncInterval ?? this.syncInterval,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Valide la configuration de la source de données
  @override
  bool isValid() {
    return super.isValid() && 
           spreadsheetId.isNotEmpty &&
           _isValidSpreadsheetId(spreadsheetId);
  }

  /// Vérifie si l'ID de la feuille de calcul est valide
  bool _isValidSpreadsheetId(String id) {
    // Format typique d'un ID Google Sheets
    final regex = RegExp(r'^[a-zA-Z0-9-_]{44}$');
    return regex.hasMatch(id);
  }

  /// Retourne l'URL de la feuille de calcul
  String get spreadsheetUrl => 'https://docs.google.com/spreadsheets/d/$spreadsheetId';

  /// Retourne la plage complète avec le nom de la feuille
  String get fullRange {
    final sheet = sheetName ?? 'Sheet1';
    final rangeStr = range ?? 'A:Z';
    return '$sheet!$rangeStr';
  }

  @override
  String toString() {
    return 'GoogleSheetsDataSource{id: $id, name: $name, spreadsheetId: $spreadsheetId, sheetName: $sheetName}';
  }
}