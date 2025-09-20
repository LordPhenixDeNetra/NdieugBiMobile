import 'package:flutter/foundation.dart';
import '../../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  
  ConnectivityProvider() {
    _initialize();
  }

  // Getters that delegate to the service
  ConnectivityStatus get status => _connectivityService.status;
  bool get isOnline => _connectivityService.isOnline;
  bool get isOffline => _connectivityService.isOffline;
  bool get isChecking => _connectivityService.isChecking;
  bool get hasInternetAccess => _connectivityService.hasInternetAccess;
  String get connectionTypeString => _connectivityService.connectionTypeString;
  String get statusMessage => _connectivityService.statusMessage;
  DateTime? get lastOnlineTime => _connectivityService.lastOnlineTime;
  DateTime? get lastOfflineTime => _connectivityService.lastOfflineTime;
  int get reconnectAttempts => _connectivityService.reconnectAttempts;

  void _initialize() {
    // Listen to connectivity service changes
    _connectivityService.addListener(_onConnectivityChanged);
    
    // Initialize the service
    _connectivityService.initialize();
  }

  void _onConnectivityChanged() {
    // Notify UI listeners when connectivity changes
    notifyListeners();
  }

  // Delegate methods to the service
  Future<void> checkConnectivity() async {
    await _connectivityService.checkConnectivity();
  }

  Future<void> forceReconnect() async {
    await _connectivityService.forceReconnect();
  }

  Future<NetworkQuality> assessNetworkQuality() async {
    return await _connectivityService.assessNetworkQuality();
  }

  Map<String, dynamic> getConnectionInfo() {
    return _connectivityService.getConnectionInfo();
  }

  Future<bool> isHostReachable(String host, {int port = 80, Duration? timeout}) async {
    return await _connectivityService.isHostReachable(host, port: port, timeout: timeout);
  }

  Duration? getOfflineDuration() {
    return _connectivityService.getOfflineDuration();
  }

  Duration? getOnlineDuration() {
    return _connectivityService.getOnlineDuration();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}