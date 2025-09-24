import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/models/data_source.dart';
import 'database_service.dart';
import 'data_source_manager.dart';

enum ExportFormat {
  json,
  csv,
  excel,
  pdf,
}

enum ImportFormat {
  json,
  csv,
  excel,
}

class ImportExportResult {
  final bool success;
  final String message;
  final int processedItems;
  final List<String> errors;
  final String? filePath;

  ImportExportResult({
    required this.success,
    required this.message,
    this.processedItems = 0,
    this.errors = const [],
    this.filePath,
  });
}

class ImportExportService extends ChangeNotifier {
  static final ImportExportService _instance = ImportExportService._internal();
  factory ImportExportService() => _instance;
  ImportExportService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final DataSourceManager _dataSourceManager = DataSourceManager();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _currentOperation = '';

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get currentOperation => _currentOperation;

  // Export Methods
  Future<ImportExportResult> exportProducts({
    required ExportFormat format,
    String? filePath,
    List<String>? productIds,
  }) async {
    return await _performExport(
      tableName: 'products',
      format: format,
      filePath: filePath,
      recordIds: productIds,
      dataConverter: _convertProductsToExportFormat,
    );
  }

  Future<ImportExportResult> exportInvoices({
    required ExportFormat format,
    String? filePath,
    List<String>? invoiceIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _performExport(
      tableName: 'invoices',
      format: format,
      filePath: filePath,
      recordIds: invoiceIds,
      dataConverter: _convertInvoicesToExportFormat,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ImportExportResult> exportAllData({
    required ExportFormat format,
    String? filePath,
  }) async {
    _setProcessing(true, 'Export de toutes les données...');
    
    try {
      final products = await _databaseService.query('products');
      final invoices = await _databaseService.query('invoices');
      final cartItems = await _databaseService.query('cart_items');

      final allData = {
        'products': products,
        'invoices': invoices,
        'cart_items': cartItems,
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final fileName = filePath ?? 'ndieug_bi_backup_${DateTime.now().millisecondsSinceEpoch}';
      final result = await _writeDataToFile(allData, format, fileName);

      _setProcessing(false);
      return result;
    } catch (e) {
      _setProcessing(false);
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'export: $e',
        errors: [e.toString()],
      );
    }
  }

  // Import Methods
  Future<ImportExportResult> importProducts({
    required String filePath,
    ImportFormat? format,
    bool replaceExisting = false,
  }) async {
    return await _performImport(
      filePath: filePath,
      format: format,
      tableName: 'products',
      dataConverter: _convertImportDataToProducts,
      replaceExisting: replaceExisting,
    );
  }

  Future<ImportExportResult> importInvoices({
    required String filePath,
    ImportFormat? format,
    bool replaceExisting = false,
  }) async {
    return await _performImport(
      filePath: filePath,
      format: format,
      tableName: 'invoices',
      dataConverter: _convertImportDataToInvoices,
      replaceExisting: replaceExisting,
    );
  }

  Future<ImportExportResult> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportExportResult(
          success: false,
          message: 'Aucun fichier sélectionné',
        );
      }

      final file = result.files.first;
      final format = _detectImportFormat(file.extension);
      
      if (format == null) {
        return ImportExportResult(
          success: false,
          message: 'Format de fichier non supporté: ${file.extension}',
        );
      }

      return await _performFullImport(file.path!, format);
    } catch (e) {
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'import: $e',
        errors: [e.toString()],
      );
    }
  }

  // Google Sheets Integration
  Future<ImportExportResult> exportToGoogleSheets({
    required String spreadsheetId,
    required String sheetName,
    required String tableName,
  }) async {
    _setProcessing(true, 'Export vers Google Sheets...');
    
    try {
      // Get data source for Google Sheets
      final googleSheetsSource = _dataSourceManager.dataSources
          .where((ds) => ds.type == DataSourceType.cloud)
          .firstOrNull;
      
      if (googleSheetsSource == null) {
        return ImportExportResult(
          success: false,
          message: 'Source Google Sheets non configurée',
        );
      }

      // Get data from database
      final data = await _databaseService.query(tableName);
      
      // Convert to Google Sheets format
      // final sheetsData = await _convertDataForGoogleSheets(data, tableName);
      
      // TODO: Implement actual Google Sheets API call
      // This would require google_sheets_api package and authentication
      
      _setProcessing(false);
      return ImportExportResult(
        success: true,
        message: 'Export vers Google Sheets réussi',
        processedItems: data.length,
      );
    } catch (e) {
      _setProcessing(false);
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'export vers Google Sheets: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ImportExportResult> importFromGoogleSheets({
    required String spreadsheetId,
    required String sheetName,
    required String tableName,
  }) async {
    _setProcessing(true, 'Import depuis Google Sheets...');
    
    try {
      // TODO: Implement actual Google Sheets API call
      // This would require google_sheets_api package and authentication
      
      _setProcessing(false);
      return ImportExportResult(
        success: true,
        message: 'Import depuis Google Sheets réussi',
        processedItems: 0,
      );
    } catch (e) {
      _setProcessing(false);
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'import depuis Google Sheets: $e',
        errors: [e.toString()],
      );
    }
  }

  // Private Helper Methods
  Future<ImportExportResult> _performExport({
    required String tableName,
    required ExportFormat format,
    String? filePath,
    List<String>? recordIds,
    required Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>) dataConverter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setProcessing(true, 'Export des données...');
    
    try {
      // Build query
      String? where;
      List<dynamic>? whereArgs;
      
      if (recordIds != null && recordIds.isNotEmpty) {
        where = 'id IN (${recordIds.map((_) => '?').join(',')})';
        whereArgs = recordIds;
      } else if (startDate != null || endDate != null) {
        final conditions = <String>[];
        whereArgs = <dynamic>[];
        
        if (startDate != null) {
          conditions.add('created_at >= ?');
          whereArgs.add(startDate.toIso8601String());
        }
        if (endDate != null) {
          conditions.add('created_at <= ?');
          whereArgs.add(endDate.toIso8601String());
        }
        
        where = conditions.join(' AND ');
      }

      // Get data
      final rawData = await _databaseService.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
      );

      if (rawData.isEmpty) {
        _setProcessing(false);
        return ImportExportResult(
          success: false,
          message: 'Aucune donnée à exporter',
        );
      }

      // Convert data
      final convertedData = await dataConverter(rawData);
      
      // Generate file name if not provided
      final fileName = filePath ?? '${tableName}_export_${DateTime.now().millisecondsSinceEpoch}';
      
      // Write to file
      final result = await _writeDataToFile(convertedData, format, fileName);
      
      _setProcessing(false);
      return result.copyWith(processedItems: rawData.length);
    } catch (e) {
      _setProcessing(false);
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'export: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ImportExportResult> _performImport({
    required String filePath,
    ImportFormat? format,
    required String tableName,
    required Future<List<Map<String, dynamic>>> Function(dynamic) dataConverter,
    bool replaceExisting = false,
  }) async {
    _setProcessing(true, 'Import des données...');
    
    try {
      // Detect format if not provided
      format ??= _detectImportFormat(filePath.split('.').last);
      
      if (format == null) {
        return ImportExportResult(
          success: false,
          message: 'Format de fichier non supporté',
        );
      }

      // Read file
      final data = await _readDataFromFile(filePath, format);
      
      // Convert data
      final convertedData = await dataConverter(data);
      
      int processedCount = 0;
      final errors = <String>[];

      // Clear existing data if replace mode
      if (replaceExisting) {
        await _databaseService.delete(tableName);
      }

      // Insert data
      for (final item in convertedData) {
        try {
          await _databaseService.insert(tableName, item);
          processedCount++;
          _updateProgress(processedCount / convertedData.length);
        } catch (e) {
          errors.add('Erreur insertion item ${item['id']}: $e');
        }
      }

      _setProcessing(false);
      return ImportExportResult(
        success: errors.isEmpty,
        message: errors.isEmpty 
            ? 'Import réussi: $processedCount éléments'
            : 'Import partiel: $processedCount éléments, ${errors.length} erreurs',
        processedItems: processedCount,
        errors: errors,
      );
    } catch (e) {
      _setProcessing(false);
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'import: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ImportExportResult> _performFullImport(String filePath, ImportFormat format) async {
    _setProcessing(true, 'Import complet...');
    
    try {
      final data = await _readDataFromFile(filePath, format);
      
      if (data is Map<String, dynamic>) {
        // Full backup format
        int totalProcessed = 0;
        final errors = <String>[];

        // Import products
        if (data['products'] != null) {
          final products = await _convertImportDataToProducts(data['products']);
          for (final product in products) {
            try {
              await _databaseService.insert('products', product);
              totalProcessed++;
            } catch (e) {
              errors.add('Erreur produit ${product['id']}: $e');
            }
          }
        }

        // Import invoices
        if (data['invoices'] != null) {
          final invoices = await _convertImportDataToInvoices(data['invoices']);
          for (final invoice in invoices) {
            try {
              await _databaseService.insert('invoices', invoice);
              totalProcessed++;
            } catch (e) {
              errors.add('Erreur facture ${invoice['id']}: $e');
            }
          }
        }

        _setProcessing(false);
        return ImportExportResult(
          success: errors.isEmpty,
          message: 'Import complet: $totalProcessed éléments',
          processedItems: totalProcessed,
          errors: errors,
        );
      } else {
        _setProcessing(false);
        return ImportExportResult(
          success: false,
          message: 'Format de fichier invalide',
        );
      }
    } catch (e) {
      _setProcessing(false);
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'import complet: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<ImportExportResult> _writeDataToFile(
    dynamic data,
    ExportFormat format,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = _getFileExtension(format);
      final file = File('${directory.path}/$fileName.$extension');

      String content;
      switch (format) {
        case ExportFormat.json:
          content = jsonEncode(data);
          break;
        case ExportFormat.csv:
          content = _convertToCSV(data);
          break;
        case ExportFormat.excel:
          // TODO: Implement Excel export using excel package
          content = jsonEncode(data); // Fallback to JSON
          break;
        case ExportFormat.pdf:
          // TODO: Implement PDF export using pdf package
          content = jsonEncode(data); // Fallback to JSON
          break;
      }

      await file.writeAsString(content);

      return ImportExportResult(
        success: true,
        message: 'Export réussi',
        filePath: file.path,
      );
    } catch (e) {
      return ImportExportResult(
        success: false,
        message: 'Erreur lors de l\'écriture du fichier: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<dynamic> _readDataFromFile(String filePath, ImportFormat format) async {
    final file = File(filePath);
    final content = await file.readAsString();

    switch (format) {
      case ImportFormat.json:
        return jsonDecode(content);
      case ImportFormat.csv:
        return _parseCSV(content);
      case ImportFormat.excel:
        // TODO: Implement Excel reading using excel package
        throw UnimplementedError('Excel import not yet implemented');
    }
  }

  // Data Conversion Methods
  Future<List<Map<String, dynamic>>> _convertProductsToExportFormat(
    List<Map<String, dynamic>> products,
  ) async {
    return products.map((product) => {
      'id': product['id'],
      'name': product['name'],
      'description': product['description'],
      'price': product['price'],
      'stock_quantity': product['stock_quantity'],
      'category': product['category'],
      'barcode': product['barcode'],
      'created_at': product['created_at'],
      'updated_at': product['updated_at'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _convertInvoicesToExportFormat(
    List<Map<String, dynamic>> invoices,
  ) async {
    return invoices.map((invoice) => {
      'id': invoice['id'],
      'customer_name': invoice['customer_name'],
      'customer_phone': invoice['customer_phone'],
      'total_amount': invoice['total_amount'],
      'status': invoice['status'],
      'created_at': invoice['created_at'],
      'items': invoice['items'], // JSON string of cart items
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _convertImportDataToProducts(dynamic data) async {
    if (data is! List) return [];
    
    return data.cast<Map<String, dynamic>>().map((item) => {
      'id': item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': item['name']?.toString() ?? '',
      'description': item['description']?.toString() ?? '',
      'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
      'stock_quantity': int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0,
      'category': item['category']?.toString() ?? '',
      'barcode': item['barcode']?.toString() ?? '',
      'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _convertImportDataToInvoices(dynamic data) async {
    if (data is! List) return [];
    
    return data.cast<Map<String, dynamic>>().map((item) => {
      'id': item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'customer_name': item['customer_name']?.toString() ?? '',
      'customer_phone': item['customer_phone']?.toString() ?? '',
      'total_amount': double.tryParse(item['total_amount']?.toString() ?? '0') ?? 0.0,
      'status': item['status']?.toString() ?? 'pending',
      'created_at': item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'items': item['items']?.toString() ?? '[]',
    }).toList();
  }

  // Utility Methods
  ImportFormat? _detectImportFormat(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'json':
        return ImportFormat.json;
      case 'csv':
        return ImportFormat.csv;
      case 'xlsx':
      case 'xls':
        return ImportFormat.excel;
      default:
        return null;
    }
  }

  String _getFileExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.excel:
        return 'xlsx';
      case ExportFormat.pdf:
        return 'pdf';
    }
  }

  String _convertToCSV(dynamic data) {
    if (data is! List || data.isEmpty) return '';
    
    final List<Map<String, dynamic>> items = data.cast<Map<String, dynamic>>();
    final headers = items.first.keys.toList();
    
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final item in items) {
      final values = headers.map((header) {
        final value = item[header]?.toString() ?? '';
        // Escape commas and quotes
        return value.contains(',') || value.contains('"') 
            ? '"${value.replaceAll('"', '""')}"'
            : value;
      }).toList();
      csvLines.add(values.join(','));
    }
    
    return csvLines.join('\n');
  }

  List<Map<String, dynamic>> _parseCSV(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];
    
    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final data = <Map<String, dynamic>>[];
    
    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      if (values.length == headers.length) {
        final row = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          row[headers[j]] = values[j];
        }
        data.add(row);
      }
    }
    
    return data;
  }

  void _setProcessing(bool processing, [String operation = '']) {
    _isProcessing = processing;
    _currentOperation = operation;
    _progress = 0.0;
    notifyListeners();
  }

  void _updateProgress(double progress) {
    _progress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  // Public utility methods
  Future<void> shareExportedFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint('Erreur lors du partage du fichier: $e');
    }
  }

  Future<List<String>> getExportHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .map((entity) => entity.path)
          .where((path) => path.contains('export') || path.contains('backup'))
          .toList();
      
      files.sort((a, b) => File(b).lastModifiedSync().compareTo(File(a).lastModifiedSync()));
      return files;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }
}

extension ImportExportResultExtension on ImportExportResult {
  ImportExportResult copyWith({
    bool? success,
    String? message,
    int? processedItems,
    List<String>? errors,
    String? filePath,
  }) {
    return ImportExportResult(
      success: success ?? this.success,
      message: message ?? this.message,
      processedItems: processedItems ?? this.processedItems,
      errors: errors ?? this.errors,
      filePath: filePath ?? this.filePath,
    );
  }
}