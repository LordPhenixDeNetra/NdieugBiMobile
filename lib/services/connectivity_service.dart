import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

enum ConnectivityStatus {
  online,
  offline,
  checking,
}

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _connectivityTimer;

  ConnectivityStatus _status = ConnectivityStatus.checking;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  bool _hasInternetAccess = false;
  DateTime? _lastOnlineTime;
  DateTime? _lastOfflineTime;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Getters
  ConnectivityStatus get status => _status;
  ConnectivityResult get connectionType => _connectionType;
  bool get isOnline => _status == ConnectivityStatus.online;
  bool get isOffline => _status == ConnectivityStatus.offline;
  bool get isChecking => _status == ConnectivityStatus.checking;
  bool get hasInternetAccess => _hasInternetAccess;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;
  int get reconnectAttempts => _reconnectAttempts;

  String get connectionTypeString {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Autre';
      case ConnectivityResult.none:
        return 'Aucune';
    }
  }

  /// Vérifie si la connexion actuelle est WiFi
  bool get isWifiConnected => _connectionType == ConnectivityResult.wifi;

  String get statusMessage {
    switch (_status) {
      case ConnectivityStatus.online:
        return 'Connecté ($connectionTypeString)';
      case ConnectivityStatus.offline:
        return 'Hors ligne';
      case ConnectivityStatus.checking:
        return 'Vérification...';
    }
  }

  Future<void> initialize() async {
    await _checkConnectivity();
    _startListening();
    _startPeriodicCheck();
  }

  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('Erreur de connectivité: $error');
      },
    );
  }

  void _startPeriodicCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      Duration(seconds: AppConstants.connectivityCheckInterval),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    _connectionType = result;
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      _updateStatus(ConnectivityStatus.checking, _connectionType);

      if (_connectionType == ConnectivityResult.none) {
        _updateStatus(ConnectivityStatus.offline, _connectionType);
        return;
      }

      final hasInternet = await _checkInternetAccess();
      if (hasInternet) {
        _updateStatus(ConnectivityStatus.online, _connectionType);
        _reconnectAttempts = 0;
      } else {
        _updateStatus(ConnectivityStatus.offline, _connectionType);
        _handleReconnectAttempt();
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de connectivité: $e');
      _updateStatus(ConnectivityStatus.offline, _connectionType);
    }
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.connectivityTestUrl),
      ).timeout(
        Duration(seconds: AppConstants.connectivityTimeout),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Test d\'accès Internet échoué: $e');
      return false;
    }
  }

  void _updateStatus(ConnectivityStatus newStatus, ConnectivityResult connectionType) {
    final previousStatus = _status;
    _status = newStatus;
    _connectionType = connectionType;
    _hasInternetAccess = newStatus == ConnectivityStatus.online;

    // Update timestamps
    if (newStatus == ConnectivityStatus.online && previousStatus != ConnectivityStatus.online) {
      _lastOnlineTime = DateTime.now();
      debugPrint('Connexion établie: $connectionTypeString');
    } else if (newStatus == ConnectivityStatus.offline && previousStatus != ConnectivityStatus.offline) {
      _lastOfflineTime = DateTime.now();
      debugPrint('Connexion perdue');
    }

    notifyListeners();
  }

  void _handleReconnectAttempt() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint('Tentative de reconnexion $_reconnectAttempts/$_maxReconnectAttempts');
      
      Timer(const Duration(seconds: 5), () {
        _checkConnectivity();
      });
    }
  }

  Future<void> forceCheck() async {
    await _checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  Future<void> forceReconnect() async {
    _reconnectAttempts = 0;
    await _checkConnectivity();
  }

  Future<void> resetReconnectAttempts() async {
    _reconnectAttempts = 0;
    notifyListeners();
  }

  Map<String, dynamic> getConnectionInfo() {
    return {
      'status': _status.toString(),
      'connectionType': connectionTypeString,
      'hasInternetAccess': _hasInternetAccess,
      'lastOnlineTime': _lastOnlineTime?.toIso8601String(),
      'lastOfflineTime': _lastOfflineTime?.toIso8601String(),
      'reconnectAttempts': _reconnectAttempts,
    };
  }

  // Assess network quality based on connection speed and stability
  Future<NetworkQuality> assessNetworkQuality() async {
    if (!isOnline) {
      return NetworkQuality.none;
    }

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse(AppConstants.connectivityTestUrl),
      ).timeout(
        Duration(seconds: AppConstants.connectivityTimeout),
      );
      stopwatch.stop();

      if (response.statusCode != 200) {
        return NetworkQuality.poor;
      }

      final responseTime = stopwatch.elapsedMilliseconds;
      
      // Assess quality based on response time
      if (responseTime < 100) {
        return NetworkQuality.excellent;
      } else if (responseTime < 300) {
        return NetworkQuality.good;
      } else if (responseTime < 1000) {
        return NetworkQuality.fair;
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'évaluation de la qualité réseau: $e');
      return NetworkQuality.poor;
    }
  }

  // Check if specific host is reachable
  Future<bool> isHostReachable(String host, {int port = 80, Duration? timeout}) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout ?? const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get connection duration since last online
  Duration? get timeSinceLastOnline {
    if (_lastOnlineTime == null) return null;
    return DateTime.now().difference(_lastOnlineTime!);
  }

  // Get connection duration since last offline
  Duration? get timeSinceLastOffline {
    if (_lastOfflineTime == null) return null;
    return DateTime.now().difference(_lastOfflineTime!);
  }

  // Get offline duration
  Duration? getOfflineDuration() {
    if (_lastOfflineTime == null) return null;
    if (isOnline && _lastOnlineTime != null) {
      return _lastOnlineTime!.difference(_lastOfflineTime!);
    }
    return DateTime.now().difference(_lastOfflineTime!);
  }

  // Get online duration
  Duration? getOnlineDuration() {
    if (_lastOnlineTime == null) return null;
    if (isOffline && _lastOfflineTime != null) {
      return _lastOfflineTime!.difference(_lastOnlineTime!);
    }
    return DateTime.now().difference(_lastOnlineTime!);
  }

  // Stream for connectivity changes
  Stream<ConnectivityStatus> get connectivityStream {
    return Stream.periodic(
      Duration(seconds: AppConstants.connectivityCheckInterval),
      (_) => _status,
    ).distinct();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }
}

enum NetworkQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}

extension NetworkQualityExtension on NetworkQuality {
  String get displayName {
    switch (this) {
      case NetworkQuality.none:
        return 'Aucune';
      case NetworkQuality.poor:
        return 'Faible';
      case NetworkQuality.fair:
        return 'Correcte';
      case NetworkQuality.good:
        return 'Bonne';
      case NetworkQuality.excellent:
        return 'Excellente';
    }
  }

  String get description {
    switch (this) {
      case NetworkQuality.none:
        return 'Pas de connexion réseau';
      case NetworkQuality.poor:
        return 'Connexion lente ou instable';
      case NetworkQuality.fair:
        return 'Connexion acceptable';
      case NetworkQuality.good:
        return 'Connexion rapide et stable';
      case NetworkQuality.excellent:
        return 'Connexion très rapide et stable';
    }
  }
}