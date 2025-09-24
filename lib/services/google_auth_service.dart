import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'authentification Google pour l'accès aux APIs
class GoogleAuthService {
  static const String _credentialsKey = 'google_credentials';
  static const String _tokenKey = 'google_access_token';
  
  // Scopes nécessaires pour Google Sheets
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ];

  GoogleSignIn? _googleSignIn;
  AccessCredentials? _credentials;
  bool _isInitialized = false;

  /// Initialise le service d'authentification
  Future<void> initialize() async {
    if (_isInitialized) return;

    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );

    // Tenter de restaurer les credentials sauvegardés
    await _loadSavedCredentials();
    
    _isInitialized = true;
  }

  /// Vérifie si l'utilisateur est authentifié
  bool get isAuthenticated => _credentials != null && !_isTokenExpired();

  /// Authentifie l'utilisateur avec Google Sign-In
  Future<bool> authenticate() async {
    try {
      if (!_isInitialized) await initialize();

      // Tenter la connexion silencieuse d'abord
      GoogleSignInAccount? account = await _googleSignIn!.signInSilently();
      
      // Si échec, demander une connexion interactive
      account ??= await _googleSignIn!.signIn();
      
      if (account == null) {
        throw Exception('Authentification annulée par l\'utilisateur');
      }

      // Obtenir les tokens d'authentification
      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.accessToken == null) {
        throw Exception('Impossible d\'obtenir le token d\'accès');
      }

      // Créer les credentials
      _credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          auth.accessToken!,
          DateTime.now().add(const Duration(hours: 1)), // Expiration estimée
        ),
        auth.idToken,
        _scopes,
      );

      // Sauvegarder les credentials
      await _saveCredentials();

      return true;
    } catch (e) {
      debugPrint('Erreur d\'authentification Google: $e');
      return false;
    }
  }

  /// Authentifie avec un compte de service (pour les environnements de production)
  Future<bool> authenticateWithServiceAccount() async {
    try {
      // Charger le fichier de credentials du service account
      final String credentialsJson = await rootBundle.loadString('assets/google_credentials.json');
      final Map<String, dynamic> credentialsMap = json.decode(credentialsJson);
      
      // Créer les credentials du service account
      final ServiceAccountCredentials serviceCredentials = ServiceAccountCredentials.fromJson(credentialsMap);
      
      // Obtenir les credentials d'accès
      final AuthClient client = await clientViaServiceAccount(serviceCredentials, _scopes);
      _credentials = client.credentials;
      
      // Sauvegarder les credentials
      await _saveCredentials();
      
      return true;
    } catch (e) {
      debugPrint('Erreur d\'authentification avec compte de service: $e');
      return false;
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      _credentials = null;
      
      // Supprimer les credentials sauvegardés
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_credentialsKey);
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  /// Retourne les credentials d'accès actuels
  AccessCredentials? get credentials => _credentials;

  /// Retourne le token d'accès actuel
  String? get accessToken => _credentials?.accessToken.data;

  /// Vérifie si le token est expiré
  bool _isTokenExpired() {
    if (_credentials == null) return true;
    final expiry = _credentials!.accessToken.expiry;
    return DateTime.now().isAfter(expiry);
  }

  /// Rafraîchit le token d'accès si nécessaire
  Future<bool> refreshTokenIfNeeded() async {
    if (!_isTokenExpired()) return true;

    try {
      // Pour Google Sign-In, on doit se reconnecter
      if (_googleSignIn != null) {
        return await authenticate();
      }
      
      // Pour les service accounts, les tokens sont généralement valides plus longtemps
      // et se rafraîchissent automatiquement
      return true;
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }

  /// Sauvegarde les credentials dans les préférences
  Future<void> _saveCredentials() async {
    if (_credentials == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final credentialsData = {
        'accessToken': _credentials!.accessToken.data,
        'tokenType': _credentials!.accessToken.type,
        'expiry': _credentials!.accessToken.expiry.toIso8601String(),
        'refreshToken': _credentials!.refreshToken,
        'scopes': _credentials!.scopes,
      };
      
      await prefs.setString(_credentialsKey, json.encode(credentialsData));
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des credentials: $e');
    }
  }

  /// Charge les credentials sauvegardés
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credentialsString = prefs.getString(_credentialsKey);
      
      if (credentialsString == null) return;
      
      final credentialsData = json.decode(credentialsString) as Map<String, dynamic>;
      
      final expiry = credentialsData['expiry'] != null 
          ? DateTime.parse(credentialsData['expiry'] as String)
          : null;
      
      _credentials = AccessCredentials(
        AccessToken(
          credentialsData['tokenType'] as String,
          credentialsData['accessToken'] as String,
          expiry ?? DateTime.now().add(const Duration(hours: 1)),
        ),
        credentialsData['refreshToken'] as String?,
        List<String>.from(credentialsData['scopes'] as List),
      );
      
      // Vérifier si le token est encore valide
      if (_isTokenExpired()) {
        _credentials = null;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des credentials: $e');
      _credentials = null;
    }
  }
}