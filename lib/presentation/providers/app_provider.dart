import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_constants.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isOnline = true;
  bool _isOfflineMode = false;
  bool _isFirstLaunch = true;
  String _language = 'fr';
  DateTime? _lastSync;

  // Getters
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isOfflineMode => _isOfflineMode;
  bool get isFirstLaunch => _isFirstLaunch;
  String get language => _language;
  DateTime? get lastSync => _lastSync;
  
  // Additional getters for missing properties
  bool get isSyncing => _isLoading; // Assuming syncing state is same as loading
  bool get lightStatusSuccess => true; // Default success status

  AppProvider() {
    _initializeApp();
    _listenToConnectivity();
  }

  /// Initialize app settings
  Future<void> _initializeApp() async {
    setLoading(true);
    
    try {
      await _loadPreferences();
      await _checkConnectivity();
    } catch (e) {
      // Handle initialization error
    } finally {
      setLoading(false);
    }
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isFirstLaunch = prefs.getBool(AppConstants.isFirstLaunchKey) ?? true;
    _isOfflineMode = prefs.getBool(AppConstants.offlineModeKey) ?? false;
    _language = prefs.getString(AppConstants.languageKey) ?? 'fr';
    
    final lastSyncString = prefs.getString(AppConstants.lastSyncKey);
    if (lastSyncString != null) {
      _lastSync = DateTime.tryParse(lastSyncString);
    }
    
    notifyListeners();
  }

  /// Listen to connectivity changes
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Toggle offline mode
  Future<void> toggleOfflineMode() async {
    _isOfflineMode = !_isOfflineMode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.offlineModeKey, _isOfflineMode);
  }

  /// Set offline mode
  Future<void> setOfflineMode(bool offlineMode) async {
    if (_isOfflineMode != offlineMode) {
      _isOfflineMode = offlineMode;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.offlineModeKey, _isOfflineMode);
    }
  }

  /// Mark first launch as completed
  Future<void> completeFirstLaunch() async {
    _isFirstLaunch = false;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isFirstLaunchKey, false);
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    if (_language != language) {
      _language = language;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.languageKey, language);
    }
  }

  /// Update last sync time
  Future<void> updateLastSync() async {
    _lastSync = DateTime.now();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.lastSyncKey, _lastSync!.toIso8601String());
  }

  /// Get connection status text
  String get connectionStatusText {
    if (_isOfflineMode) return 'Mode hors ligne';
    return _isOnline ? 'En ligne' : 'Hors ligne';
  }

  /// Get connection status color
  Color get connectionStatusColor {
    if (_isOfflineMode) return Colors.orange;
    return _isOnline ? Colors.green : Colors.red;
  }

  /// Check if app can sync
  bool get canSync => _isOnline && !_isOfflineMode;

  /// Get time since last sync
  String get timeSinceLastSync {
    if (_lastSync == null) return 'Jamais synchronisé';
    
    final difference = DateTime.now().difference(_lastSync!);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays} jour(s)';
    }
  }
}