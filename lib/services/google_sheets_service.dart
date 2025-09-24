import 'package:flutter/foundation.dart';
import 'package:gsheets/gsheets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_service.dart';

/// Service pour gérer l'intégration avec Google Sheets
class GoogleSheetsService extends ChangeNotifier {
  final GoogleAuthService _authService;

  // Clés pour SharedPreferences
  static const String _credentialsKey = 'google_sheets_credentials';
  static const String _spreadsheetIdKey = 'google_sheets_spreadsheet_id';

  // État du service
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _error;
  String? _currentSpreadsheetId;

  // Instances Google Sheets
  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;

  GoogleSheetsService(this._authService);

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get currentSpreadsheetId => _currentSpreadsheetId;
  String? get error => _error;
  Spreadsheet? get spreadsheet => _spreadsheet;
  
  /// Getter pour accéder aux feuilles de calcul
  List<Worksheet> get worksheets => _spreadsheet?.sheets ?? [];

  /// Initialise le service Google Sheets
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Initialiser le service d'authentification
      await _authService.initialize();
      
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Erreur d\'initialisation: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authentifie l'utilisateur avec Google
  Future<bool> authenticate() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Utiliser le service d'authentification
        final success = await _authService.authenticate();
        
        if (success) {
        // Initialiser l'API Sheets avec les credentials
        final credentials = _authService.credentials;
        if (credentials != null) {
          _gsheets = GSheets(credentials.accessToken.data);
          _isAuthenticated = true;
          _error = null;
        }
      } else {
        _error = 'Échec de l\'authentification Google';
      }
      
      return success;
    } catch (e) {
      _error = 'Erreur d\'authentification: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Se connecte à une feuille de calcul spécifique
  Future<bool> connectToSpreadsheet(String spreadsheetId) async {
    if (!_isAuthenticated || _gsheets == null) {
      _setError('Authentification requise');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _connectToSpreadsheet(spreadsheetId);
      await _saveSpreadsheetId(spreadsheetId);
      return true;
    } catch (e) {
      _setError('Erreur de connexion à la feuille: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Crée une nouvelle feuille de calcul
  Future<String?> createSpreadsheet(String title) async {
    if (!_isAuthenticated || _gsheets == null) {
      _setError('Authentification requise');
      return null;
    }

    _setLoading(true);
    _setError(null);

    try {
      final spreadsheet = await _gsheets!.createSpreadsheet(title);
      _spreadsheet = spreadsheet;
      _currentSpreadsheetId = spreadsheet.id;
      
      await _saveSpreadsheetId(spreadsheet.id);
      
      // Créer les feuilles par défaut pour NdieugBi
      await _setupDefaultSheets();
      
      notifyListeners();
      return spreadsheet.id;
    } catch (e) {
      _setError('Erreur de création de feuille: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Configure les feuilles par défaut pour NdieugBi
  Future<void> _setupDefaultSheets() async {
    if (_spreadsheet == null) return;

    try {
      // Feuille Produits
      final productsSheet = await _spreadsheet!.addWorksheet('Produits');
      await productsSheet.values.insertRow(1, [
        'ID', 'Nom', 'Description', 'Prix', 'Stock', 'Code-barres', 
        'Catégorie', 'Date création', 'Date modification'
      ]);

      // Feuille Clients
      final clientsSheet = await _spreadsheet!.addWorksheet('Clients');
      await clientsSheet.values.insertRow(1, [
        'ID', 'Nom', 'Prénom', 'Email', 'Téléphone', 'Adresse',
        'Date création', 'Date modification'
      ]);

      // Feuille Factures
      final invoicesSheet = await _spreadsheet!.addWorksheet('Factures');
      await invoicesSheet.values.insertRow(1, [
        'ID', 'Numéro', 'Client ID', 'Date', 'Total', 'Statut',
        'Date création', 'Date modification'
      ]);

      // Feuille Articles Facture
      final invoiceItemsSheet = await _spreadsheet!.addWorksheet('Articles_Facture');
      await invoiceItemsSheet.values.insertRow(1, [
        'ID', 'Facture ID', 'Produit ID', 'Quantité', 'Prix unitaire',
        'Total', 'Date création'
      ]);

      debugPrint('Feuilles par défaut créées avec succès');
    } catch (e) {
      debugPrint('Erreur lors de la création des feuilles par défaut: $e');
    }
  }

  /// Synchronise les données depuis Google Sheets vers l'application
  Future<Map<String, List<Map<String, dynamic>>>> syncFromSheets() async {
    if (!isAuthenticated || _spreadsheet == null) {
      throw Exception('Authentification Google Sheets requise');
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = <String, List<Map<String, dynamic>>>{};
      final worksheets = _spreadsheet!.sheets;

      for (final worksheet in worksheets) {
        try {
          final sheetData = await readSheetData(worksheet.title);
          final dataList = sheetData['data'] as List<Map<String, dynamic>>;
          if (dataList.isNotEmpty) {
            result[worksheet.title] = dataList;
          }
        } catch (e) {
          debugPrint('Erreur lecture feuille ${worksheet.title}: $e');
          // Continuer avec les autres feuilles même si une échoue
        }
      }

      return result;
    } catch (e) {
      _setError('Erreur synchronisation depuis Google Sheets: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Synchronise les données vers Google Sheets
  Future<bool> syncToSheets(Map<String, List<Map<String, dynamic>>> data) async {
    if (_spreadsheet == null) {
      _setError('Aucune feuille de calcul connectée');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      for (final entry in data.entries) {
        final sheetName = entry.key;
        final sheetData = entry.value;

        // Trouver ou créer la feuille
        Worksheet? worksheet = _spreadsheet!.worksheetByTitle(sheetName);
        worksheet ??= await _spreadsheet!.addWorksheet(sheetName);

        // Effacer le contenu existant (sauf les en-têtes)
        if (worksheet.rowCount > 1) {
          // Effacer toutes les lignes sauf la première (en-têtes)
          await worksheet.clear();
          // Remettre les en-têtes si nécessaire
          final headers = await worksheet.values.row(1);
          if (headers.isNotEmpty) {
            await worksheet.values.insertRow(1, headers);
          }
        }

        // Insérer les nouvelles données
        if (sheetData.isNotEmpty) {
          final headers = await worksheet.values.row(1);
          final rows = sheetData.map((item) {
            return headers.map((header) => item[header]?.toString() ?? '').toList();
          }).toList();

          await worksheet.values.insertRows(2, rows);
        }
      }

      return true;
    } catch (e) {
      _setError('Erreur de synchronisation vers Sheets: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtient les informations de la feuille de calcul
  Future<Map<String, dynamic>> getSpreadsheetInfo() async {
    if (_spreadsheet == null) return {};

    final worksheetsList = _spreadsheet!.sheets;
    return {
      'id': _spreadsheet!.id,
      'title': _spreadsheet!.data.properties.title ?? 'Sans titre',
      'url': 'https://docs.google.com/spreadsheets/d/${_spreadsheet!.id}',
      'worksheets': worksheetsList.map((ws) => {
        'title': ws.title,
        'id': ws.id,
        'rowCount': ws.rowCount,
        'columnCount': ws.columnCount,
      }).toList(),
    };
  }

  /// Lit les données d'une feuille spécifique avec pagination
  Future<Map<String, dynamic>> readSheetData(
    String sheetName, {
    int? startRow,
    int? endRow,
    List<String>? columns,
  }) async {
    if (_spreadsheet == null) {
      _setError('Aucune feuille de calcul connectée');
      return {'data': [], 'total': 0};
    }

    try {
      final worksheet = _spreadsheet!.worksheetByTitle(sheetName);
      if (worksheet == null) {
        _setError('Feuille "$sheetName" non trouvée');
        return {'data': [], 'total': 0};
      }

      final allRows = await worksheet.values.allRows();
      if (allRows.isEmpty) return {'data': [], 'total': 0};

      final headers = allRows.first;
      final dataRows = allRows.skip(1).toList();

      // Filtrer les colonnes si spécifiées
      List<int> columnIndices = [];
      if (columns != null && columns.isNotEmpty) {
        for (final column in columns) {
          final index = headers.indexOf(column);
          if (index != -1) columnIndices.add(index);
        }
      } else {
        columnIndices = List.generate(headers.length, (index) => index);
      }

      // Appliquer la pagination
      final start = (startRow ?? 1) - 1;
      final end = endRow != null ? (endRow - 1).clamp(0, dataRows.length) : dataRows.length;
      final paginatedRows = dataRows.skip(start).take(end - start).toList();

      // Convertir en Map
      final data = paginatedRows.map((row) {
        final item = <String, dynamic>{};
        for (final index in columnIndices) {
          if (index < headers.length) {
            final header = headers[index];
            final value = index < row.length ? row[index] : '';
            item[header] = value;
          }
        }
        return item;
      }).toList();

      return {
        'data': data,
        'total': dataRows.length,
        'headers': columnIndices.map((i) => headers[i]).toList(),
      };
    } catch (e) {
      _setError('Erreur de lecture: $e');
      return {'data': [], 'total': 0};
    }
  }

  /// Recherche des données dans une feuille
  Future<List<Map<String, dynamic>>> searchInSheet(
    String sheetName,
    String searchTerm, {
    List<String>? searchColumns,
    bool caseSensitive = false,
  }) async {
    if (_spreadsheet == null) {
      _setError('Aucune feuille de calcul connectée');
      return [];
    }

    try {
      final worksheet = _spreadsheet!.worksheetByTitle(sheetName);
      if (worksheet == null) {
        _setError('Feuille "$sheetName" non trouvée');
        return [];
      }

      final allRows = await worksheet.values.allRows();
      if (allRows.isEmpty) return [];

      final headers = allRows.first;
      final dataRows = allRows.skip(1).toList();

      // Déterminer les colonnes de recherche
      List<int> searchIndices = [];
      if (searchColumns != null && searchColumns.isNotEmpty) {
        for (final column in searchColumns) {
          final index = headers.indexOf(column);
          if (index != -1) searchIndices.add(index);
        }
      } else {
        searchIndices = List.generate(headers.length, (index) => index);
      }

      final searchTermLower = caseSensitive ? searchTerm : searchTerm.toLowerCase();

      // Filtrer les lignes qui contiennent le terme de recherche
      final matchingRows = dataRows.where((row) {
        return searchIndices.any((index) {
          if (index >= row.length) return false;
          final cellValue = caseSensitive ? row[index] : row[index].toLowerCase();
          return cellValue.contains(searchTermLower);
        });
      }).toList();

      // Convertir en Map
      return matchingRows.map((row) {
        final item = <String, dynamic>{};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          item[headers[i]] = row[i];
        }
        return item;
      }).toList();
    } catch (e) {
      _setError('Erreur de recherche: $e');
      return [];
    }
  }

  /// Obtient les statistiques d'une feuille
  Future<Map<String, dynamic>> getSheetStatistics(String sheetName) async {
    if (_spreadsheet == null) {
      _setError('Aucune feuille de calcul connectée');
      return {};
    }

    try {
      final worksheet = _spreadsheet!.worksheetByTitle(sheetName);
      if (worksheet == null) {
        _setError('Feuille "$sheetName" non trouvée');
        return {};
      }

      final allRows = await worksheet.values.allRows();
      if (allRows.isEmpty) {
        return {
          'totalRows': 0,
          'totalColumns': 0,
          'dataRows': 0,
          'emptyRows': 0,
        };
      }

      final headers = allRows.first;
      final dataRows = allRows.skip(1).toList();
      
      int emptyRows = 0;
      int nonEmptyRows = 0;

      for (final row in dataRows) {
        if (row.every((cell) => cell.trim().isEmpty)) {
          emptyRows++;
        } else {
          nonEmptyRows++;
        }
      }

      return {
        'totalRows': allRows.length,
        'totalColumns': headers.length,
        'dataRows': nonEmptyRows,
        'emptyRows': emptyRows,
        'headers': headers,
        'lastModified': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _setError('Erreur de calcul des statistiques: $e');
      return {};
    }
  }

  /// Valide la structure d'une feuille
  Future<Map<String, dynamic>> validateSheetStructure(
    String sheetName,
    List<String> requiredHeaders,
  ) async {
    if (_spreadsheet == null) {
      _setError('Aucune feuille de calcul connectée');
      return {'isValid': false, 'errors': ['Aucune feuille de calcul connectée']};
    }

    try {
      final worksheet = _spreadsheet!.worksheetByTitle(sheetName);
      if (worksheet == null) {
        return {
          'isValid': false,
          'errors': ['Feuille "$sheetName" non trouvée']
        };
      }

      final allRows = await worksheet.values.allRows();
      if (allRows.isEmpty) {
        return {
          'isValid': false,
          'errors': ['La feuille est vide']
        };
      }

      final headers = allRows.first;
      final errors = <String>[];
      final warnings = <String>[];

      // Vérifier les en-têtes requis
      for (final requiredHeader in requiredHeaders) {
        if (!headers.contains(requiredHeader)) {
          errors.add('En-tête manquant: "$requiredHeader"');
        }
      }

      // Vérifier les doublons d'en-têtes
      final headerSet = <String>{};
      for (final header in headers) {
        if (header.trim().isNotEmpty) {
          if (headerSet.contains(header)) {
            warnings.add('En-tête dupliqué: "$header"');
          } else {
            headerSet.add(header);
          }
        }
      }

      // Vérifier les en-têtes vides
      if (headers.any((header) => header.trim().isEmpty)) {
        warnings.add('Certains en-têtes sont vides');
      }

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'headers': headers,
        'requiredHeaders': requiredHeaders,
        'missingHeaders': requiredHeaders.where((h) => !headers.contains(h)).toList(),
      };
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Erreur de validation: $e']
      };
    }
  }

  // Déconnexion
  Future<void> disconnect() async {
    _gsheets = null;
    _spreadsheet = null;
    _isAuthenticated = false;
    _currentSpreadsheetId = null;
    _error = null;

    // Supprimer les credentials sauvegardés
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_credentialsKey);
    await prefs.remove(_spreadsheetIdKey);

    notifyListeners();
  }

  // Méthodes privées
  Future<void> _connectToSpreadsheet(String spreadsheetId) async {
    _spreadsheet = await _gsheets!.spreadsheet(spreadsheetId);
    _currentSpreadsheetId = spreadsheetId;
    notifyListeners();
  }

  Future<void> _saveSpreadsheetId(String spreadsheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spreadsheetIdKey, spreadsheetId);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

   /// Supprime une facture de Google Sheets
  Future<bool> deleteInvoice(String invoiceId) async {
    if (_spreadsheet == null) {
      _setError('Aucune feuille de calcul connectée');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Supprimer de la feuille Factures
      final invoicesSheet = _spreadsheet!.worksheetByTitle('Factures');
      if (invoicesSheet != null) {
        final rows = await invoicesSheet.values.allRows();
        if (rows.isNotEmpty) {
          final headers = rows.first;
          final idIndex = headers.indexOf('ID');
          
          if (idIndex != -1) {
            for (int i = 1; i < rows.length; i++) {
              if (i < rows.length && idIndex < rows[i].length && rows[i][idIndex] == invoiceId) {
                await invoicesSheet.deleteRow(i + 1);
                break;
              }
            }
          }
        }
      }

      // Supprimer les articles de facture associés
      final invoiceItemsSheet = _spreadsheet!.worksheetByTitle('Articles_Facture');
      if (invoiceItemsSheet != null) {
        final rows = await invoiceItemsSheet.values.allRows();
        if (rows.isNotEmpty) {
          final headers = rows.first;
          final invoiceIdIndex = headers.indexOf('Facture ID');
          
          if (invoiceIdIndex != -1) {
            // Supprimer en ordre inverse pour éviter les problèmes d'index
            for (int i = rows.length - 1; i >= 1; i--) {
              if (invoiceIdIndex < rows[i].length && rows[i][invoiceIdIndex] == invoiceId) {
                await invoiceItemsSheet.deleteRow(i + 1);
              }
            }
          }
        }
      }

      return true;
    } catch (e) {
      _setError('Erreur de suppression de facture: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}