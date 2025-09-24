import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Configuration pour les requêtes API
class ApiConfig {
  final String baseUrl;
  final Map<String, String> headers;
  final Duration timeout;
  final bool enableLogging;

  const ApiConfig({
    required this.baseUrl,
    this.headers = const {},
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = true,
  });
}

/// Réponse API standardisée
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.metadata,
  });

  factory ApiResponse.success(T data, {int? statusCode, Map<String, dynamic>? metadata}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode, Map<String, dynamic>? metadata}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      metadata: metadata,
    );
  }
}

/// Service API REST pour communiquer avec le backend Rust
class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  ApiConfig? _config;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get baseUrl => _config?.baseUrl;

  /// Initialise le service API
  void initialize(ApiConfig config) {
    _config = config;
    
    _dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.timeout,
      receiveTimeout: config.timeout,
      sendTimeout: config.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...config.headers,
      },
    ));

    // Intercepteur pour les logs
    if (config.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    // Intercepteur pour la gestion des erreurs
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        debugPrint('Erreur API: ${error.message}');
        handler.next(error);
      },
    ));

    _isInitialized = true;
    notifyListeners();
  }

  /// Teste la connexion à l'API
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;

    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Test de connexion API échoué: $e');
      return false;
    }
  }

  /// Effectue une requête GET
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    if (!_isInitialized) {
      return ApiResponse.error('Service API non initialisé');
    }

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = fromJson != null 
            ? fromJson(response.data)
            : response.data as T;
        
        return ApiResponse.success(
          data,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers.map},
        );
      } else {
        return ApiResponse.error(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: $e');
    }
  }

  /// Effectue une requête POST
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    if (!_isInitialized) {
      return ApiResponse.error('Service API non initialisé');
    }

    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = fromJson != null 
            ? fromJson(response.data)
            : response.data as T;
        
        return ApiResponse.success(
          responseData,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers.map},
        );
      } else {
        return ApiResponse.error(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: $e');
    }
  }

  /// Effectue une requête PUT
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    if (!_isInitialized) {
      return ApiResponse.error('Service API non initialisé');
    }

    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = fromJson != null 
            ? fromJson(response.data)
            : response.data as T;
        
        return ApiResponse.success(
          responseData,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers.map},
        );
      } else {
        return ApiResponse.error(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: $e');
    }
  }

  /// Effectue une requête DELETE
  Future<ApiResponse<bool>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    if (!_isInitialized) {
      return ApiResponse.error('Service API non initialisé');
    }

    try {
      final response = await _dio.delete(
        endpoint,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(
          true,
          statusCode: response.statusCode,
          metadata: {'headers': response.headers.map},
        );
      } else {
        return ApiResponse.error(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: $e');
    }
  }

  /// Gestion des erreurs Dio
  ApiResponse<T> _handleDioError<T>(DioException e) {
    String errorMessage;
    int? statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Timeout de connexion';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Timeout d\'envoi';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Timeout de réception';
        break;
      case DioExceptionType.badResponse:
        errorMessage = 'Réponse invalide: ${e.response?.statusMessage}';
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Requête annulée';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Erreur de connexion';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Erreur inconnue: ${e.message}';
        break;
      default:
        errorMessage = 'Erreur réseau: ${e.message}';
    }

    return ApiResponse.error(errorMessage, statusCode: statusCode);
  }

  /// Met à jour la configuration
  void updateConfig(ApiConfig config) {
    initialize(config);
  }

  /// Met à jour les headers par défaut
  void updateHeaders(Map<String, String> headers) {
    if (_isInitialized) {
      _dio.options.headers.addAll(headers);
    }
  }

  /// Supprime un header
  void removeHeader(String key) {
    if (_isInitialized) {
      _dio.options.headers.remove(key);
    }
  }

  /// Annule toutes les requêtes en cours
  void cancelRequests() {
    if (_isInitialized) {
      _dio.close(force: true);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _dio.close();
    }
    super.dispose();
  }
}