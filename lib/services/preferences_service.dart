import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clés des préférences
class PreferenceKeys {
  static const String dataSourceConfig = 'data_source_config';
  static const String syncConfig = 'sync_config';
  static const String connectionSettings = 'connection_settings';
  static const String appSettings = 'app_settings';
  static const String userPreferences = 'user_preferences';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String offlineMode = 'offline_mode';
  static const String autoSync = 'auto_sync';
  static const String syncInterval = 'sync_interval';
  static const String wifiOnlySync = 'wifi_only_sync';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String firstLaunch = 'first_launch';
  static const String onboardingCompleted = 'onboarding_completed';
}

/// Configuration des paramètres de l'application
class AppSettings {
  final String themeMode;
  final String language;
  final bool enableNotifications;
  final bool enableSounds;
  final bool enableVibration;
  final bool enableAnalytics;
  final bool enableCrashReporting;

  const AppSettings({
    this.themeMode = 'system',
    this.language = 'fr',
    this.enableNotifications = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.enableAnalytics = false,
    this.enableCrashReporting = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'language': language,
      'enable_notifications': enableNotifications,
      'enable_sounds': enableSounds,
      'enable_vibration': enableVibration,
      'enable_analytics': enableAnalytics,
      'enable_crash_reporting': enableCrashReporting,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['theme_mode'] ?? 'system',
      language: json['language'] ?? 'fr',
      enableNotifications: json['enable_notifications'] ?? true,
      enableSounds: json['enable_sounds'] ?? true,
      enableVibration: json['enable_vibration'] ?? true,
      enableAnalytics: json['enable_analytics'] ?? false,
      enableCrashReporting: json['enable_crash_reporting'] ?? false,
    );
  }

  AppSettings copyWith({
    String? themeMode,
    String? language,
    bool? enableNotifications,
    bool? enableSounds,
    bool? enableVibration,
    bool? enableAnalytics,
    bool? enableCrashReporting,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      enableVibration: enableVibration ?? this.enableVibration,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
    );
  }
}

/// Préférences utilisateur
class UserPreferences {
  final bool showTutorials;
  final bool compactView;
  final bool showPricesInList;
  final bool autoSaveInvoices;
  final String defaultCurrency;
  final int itemsPerPage;
  final String dateFormat;
  final String timeFormat;

  const UserPreferences({
    this.showTutorials = true,
    this.compactView = false,
    this.showPricesInList = true,
    this.autoSaveInvoices = true,
    this.defaultCurrency = 'XOF',
    this.itemsPerPage = 20,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = 'HH:mm',
  });

  Map<String, dynamic> toJson() {
    return {
      'show_tutorials': showTutorials,
      'compact_view': compactView,
      'show_prices_in_list': showPricesInList,
      'auto_save_invoices': autoSaveInvoices,
      'default_currency': defaultCurrency,
      'items_per_page': itemsPerPage,
      'date_format': dateFormat,
      'time_format': timeFormat,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      showTutorials: json['show_tutorials'] ?? true,
      compactView: json['compact_view'] ?? false,
      showPricesInList: json['show_prices_in_list'] ?? true,
      autoSaveInvoices: json['auto_save_invoices'] ?? true,
      defaultCurrency: json['default_currency'] ?? 'XOF',
      itemsPerPage: json['items_per_page'] ?? 20,
      dateFormat: json['date_format'] ?? 'dd/MM/yyyy',
      timeFormat: json['time_format'] ?? 'HH:mm',
    );
  }

  UserPreferences copyWith({
    bool? showTutorials,
    bool? compactView,
    bool? showPricesInList,
    bool? autoSaveInvoices,
    String? defaultCurrency,
    int? itemsPerPage,
    String? dateFormat,
    String? timeFormat,
  }) {
    return UserPreferences(
      showTutorials: showTutorials ?? this.showTutorials,
      compactView: compactView ?? this.compactView,
      showPricesInList: showPricesInList ?? this.showPricesInList,
      autoSaveInvoices: autoSaveInvoices ?? this.autoSaveInvoices,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}

/// Service de gestion des préférences
class PreferencesService extends ChangeNotifier {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  AppSettings _appSettings = const AppSettings();
  UserPreferences _userPreferences = const UserPreferences();

  // Getters
  bool get isInitialized => _isInitialized;
  AppSettings get appSettings => _appSettings;
  UserPreferences get userPreferences => _userPreferences;

  /// Initialise le service des préférences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAllPreferences();
      _isInitialized = true;
      notifyListeners();
      debugPrint('PreferencesService initialisé');
    } catch (e) {
      debugPrint('Erreur d\'initialisation du PreferencesService: $e');
      rethrow;
    }
  }

  /// Charge toutes les préférences
  Future<void> _loadAllPreferences() async {
    await _loadAppSettings();
    await _loadUserPreferences();
  }

  /// Charge les paramètres de l'application
  Future<void> _loadAppSettings() async {
    try {
      final settingsJson = _prefs?.getString(PreferenceKeys.appSettings);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _appSettings = AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Erreur chargement paramètres app: $e');
    }
  }

  /// Charge les préférences utilisateur
  Future<void> _loadUserPreferences() async {
    try {
      final preferencesJson = _prefs?.getString(PreferenceKeys.userPreferences);
      if (preferencesJson != null) {
        final preferencesMap = jsonDecode(preferencesJson) as Map<String, dynamic>;
        _userPreferences = UserPreferences.fromJson(preferencesMap);
      }
    } catch (e) {
      debugPrint('Erreur chargement préférences utilisateur: $e');
    }
  }

  /// Met à jour les paramètres de l'application
  Future<void> updateAppSettings(AppSettings settings) async {
    _appSettings = settings;
    await _saveAppSettings();
    notifyListeners();
  }

  /// Met à jour les préférences utilisateur
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    _userPreferences = preferences;
    await _saveUserPreferences();
    notifyListeners();
  }

  /// Sauvegarde les paramètres de l'application
  Future<void> _saveAppSettings() async {
    try {
      await _prefs?.setString(
        PreferenceKeys.appSettings,
        jsonEncode(_appSettings.toJson()),
      );
    } catch (e) {
      debugPrint('Erreur sauvegarde paramètres app: $e');
    }
  }

  /// Sauvegarde les préférences utilisateur
  Future<void> _saveUserPreferences() async {
    try {
      await _prefs?.setString(
        PreferenceKeys.userPreferences,
        jsonEncode(_userPreferences.toJson()),
      );
    } catch (e) {
      debugPrint('Erreur sauvegarde préférences utilisateur: $e');
    }
  }

  // ==================== MÉTHODES GÉNÉRIQUES ====================

  /// Sauvegarde une chaîne de caractères
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs?.setString(key, value) ?? false;
    } catch (e) {
      debugPrint('Erreur sauvegarde string $key: $e');
      return false;
    }
  }

  /// Récupère une chaîne de caractères
  String? getString(String key, {String? defaultValue}) {
    try {
      return _prefs?.getString(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Erreur récupération string $key: $e');
      return defaultValue;
    }
  }

  /// Sauvegarde un entier
  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs?.setInt(key, value) ?? false;
    } catch (e) {
      debugPrint('Erreur sauvegarde int $key: $e');
      return false;
    }
  }

  /// Récupère un entier
  int? getInt(String key, {int? defaultValue}) {
    try {
      return _prefs?.getInt(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Erreur récupération int $key: $e');
      return defaultValue;
    }
  }

  /// Sauvegarde un booléen
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs?.setBool(key, value) ?? false;
    } catch (e) {
      debugPrint('Erreur sauvegarde bool $key: $e');
      return false;
    }
  }

  /// Récupère un booléen
  bool? getBool(String key, {bool? defaultValue}) {
    try {
      return _prefs?.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Erreur récupération bool $key: $e');
      return defaultValue;
    }
  }

  /// Sauvegarde un double
  Future<bool> setDouble(String key, double value) async {
    try {
      return await _prefs?.setDouble(key, value) ?? false;
    } catch (e) {
      debugPrint('Erreur sauvegarde double $key: $e');
      return false;
    }
  }

  /// Récupère un double
  double? getDouble(String key, {double? defaultValue}) {
    try {
      return _prefs?.getDouble(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Erreur récupération double $key: $e');
      return defaultValue;
    }
  }

  /// Sauvegarde une liste de chaînes
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs?.setStringList(key, value) ?? false;
    } catch (e) {
      debugPrint('Erreur sauvegarde string list $key: $e');
      return false;
    }
  }

  /// Récupère une liste de chaînes
  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    try {
      return _prefs?.getStringList(key) ?? defaultValue;
    } catch (e) {
      debugPrint('Erreur récupération string list $key: $e');
      return defaultValue;
    }
  }

  /// Sauvegarde un objet JSON
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('Erreur sauvegarde JSON $key: $e');
      return false;
    }
  }

  /// Récupère un objet JSON
  Map<String, dynamic>? getJson(String key, {Map<String, dynamic>? defaultValue}) {
    try {
      final jsonString = getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('Erreur récupération JSON $key: $e');
      return defaultValue;
    }
  }

  /// Supprime une préférence
  Future<bool> remove(String key) async {
    try {
      return await _prefs?.remove(key) ?? false;
    } catch (e) {
      debugPrint('Erreur suppression $key: $e');
      return false;
    }
  }

  /// Supprime toutes les préférences
  Future<bool> clear() async {
    try {
      return await _prefs?.clear() ?? false;
    } catch (e) {
      debugPrint('Erreur suppression toutes préférences: $e');
      return false;
    }
  }

  /// Vérifie si une clé existe
  bool containsKey(String key) {
    try {
      return _prefs?.containsKey(key) ?? false;
    } catch (e) {
      debugPrint('Erreur vérification clé $key: $e');
      return false;
    }
  }

  /// Récupère toutes les clés
  Set<String> getKeys() {
    try {
      return _prefs?.getKeys() ?? <String>{};
    } catch (e) {
      debugPrint('Erreur récupération clés: $e');
      return <String>{};
    }
  }

  // ==================== MÉTHODES SPÉCIALISÉES ====================

  /// Vérifie si c'est le premier lancement
  bool isFirstLaunch() {
    return getBool(PreferenceKeys.firstLaunch, defaultValue: true) ?? true;
  }

  /// Marque le premier lancement comme terminé
  Future<void> setFirstLaunchCompleted() async {
    await setBool(PreferenceKeys.firstLaunch, false);
  }

  /// Vérifie si l'onboarding est terminé
  bool isOnboardingCompleted() {
    return getBool(PreferenceKeys.onboardingCompleted, defaultValue: false) ?? false;
  }

  /// Marque l'onboarding comme terminé
  Future<void> setOnboardingCompleted() async {
    await setBool(PreferenceKeys.onboardingCompleted, true);
  }

  /// Récupère le timestamp de la dernière synchronisation
  DateTime? getLastSyncTimestamp() {
    final timestamp = getInt(PreferenceKeys.lastSyncTimestamp);
    return timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Sauvegarde le timestamp de la dernière synchronisation
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await setInt(PreferenceKeys.lastSyncTimestamp, timestamp.millisecondsSinceEpoch);
  }

  /// Vérifie si le mode hors ligne est activé
  bool isOfflineModeEnabled() {
    return getBool(PreferenceKeys.offlineMode, defaultValue: false) ?? false;
  }

  /// Active/désactive le mode hors ligne
  Future<void> setOfflineMode(bool enabled) async {
    await setBool(PreferenceKeys.offlineMode, enabled);
  }

  /// Vérifie si la synchronisation automatique est activée
  bool isAutoSyncEnabled() {
    return getBool(PreferenceKeys.autoSync, defaultValue: true) ?? true;
  }

  /// Active/désactive la synchronisation automatique
  Future<void> setAutoSync(bool enabled) async {
    await setBool(PreferenceKeys.autoSync, enabled);
  }

  /// Récupère l'intervalle de synchronisation (en minutes)
  int getSyncInterval() {
    return getInt(PreferenceKeys.syncInterval, defaultValue: 30) ?? 30;
  }

  /// Définit l'intervalle de synchronisation (en minutes)
  Future<void> setSyncInterval(int minutes) async {
    await setInt(PreferenceKeys.syncInterval, minutes);
  }

  /// Vérifie si la synchronisation ne doit se faire qu'en WiFi
  bool isWifiOnlySyncEnabled() {
    return getBool(PreferenceKeys.wifiOnlySync, defaultValue: true) ?? true;
  }

  /// Active/désactive la synchronisation WiFi uniquement
  Future<void> setWifiOnlySync(bool enabled) async {
    await setBool(PreferenceKeys.wifiOnlySync, enabled);
  }
}