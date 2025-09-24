import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// Service de gestion des connexions WebSocket
class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  String? _url;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get url => _url;

  /// Connecte au serveur WebSocket
  Future<bool> connect(String url, {Map<String, String>? headers}) async {
    if (_isConnected || _isConnecting) {
      debugPrint('WebSocket déjà connecté ou en cours de connexion');
      return _isConnected;
    }

    _url = url;
    _isConnecting = true;
    _shouldReconnect = true;
    notifyListeners();

    try {
      debugPrint('Connexion WebSocket à: $url');
      
      // Création du canal WebSocket
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: headers,
      );

      // Écoute des messages
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      // Démarrage du heartbeat
      _startHeartbeat();
      
      debugPrint('WebSocket connecté avec succès');
      onConnected?.call();
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Erreur de connexion WebSocket: $e');
      _isConnecting = false;
      _handleConnectionError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Déconnecte du serveur WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    await _cleanup();
    debugPrint('WebSocket déconnecté');
  }

  /// Envoie un message via WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket non connecté, impossible d\'envoyer le message');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      debugPrint('Message envoyé: $jsonMessage');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      onError?.call('Erreur d\'envoi: $e');
    }
  }

  /// Envoie un ping pour maintenir la connexion
  void ping() {
    sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Teste la connexion WebSocket
  Future<bool> testConnection(String url) async {
    try {
      final testChannel = IOWebSocketChannel.connect(Uri.parse(url));
      
      final completer = Completer<bool>();
      late StreamSubscription subscription;
      
      // Timeout pour le test
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      subscription = testChannel.stream.listen(
        (message) {
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Envoie un message de test
      testChannel.sink.add(jsonEncode({'type': 'test'}));

      final result = await completer.future;
      
      // Nettoyage
      await subscription.cancel();
      await testChannel.sink.close();
      
      return result;
    } catch (e) {
      debugPrint('Erreur lors du test de connexion: $e');
      return false;
    }
  }

  /// Gestion des messages reçus
  void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message.toString());
      debugPrint('Message reçu: $data');
      
      // Gestion des messages système
      if (data['type'] == 'pong') {
        debugPrint('Pong reçu');
        return;
      }
      
      onMessage?.call(data);
    } catch (e) {
      debugPrint('Erreur lors du traitement du message: $e');
      onError?.call('Erreur de traitement: $e');
    }
  }

  /// Gestion des erreurs
  void _onError(dynamic error) {
    debugPrint('Erreur WebSocket: $error');
    _handleConnectionError(error.toString());
  }

  /// Gestion de la déconnexion
  void _onDisconnected() {
    debugPrint('WebSocket déconnecté');
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();
    notifyListeners();
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Gestion des erreurs de connexion
  void _handleConnectionError(String error) {
    onError?.call(error);
    if (_shouldReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// Programme une reconnexion automatique
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    
    _reconnectAttempts++;
    debugPrint('Tentative de reconnexion $_reconnectAttempts/$_maxReconnectAttempts dans ${_reconnectDelay.inSeconds}s');
    
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_shouldReconnect && _url != null) {
        await connect(_url!);
      }
    });
  }

  /// Démarre le heartbeat
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        ping();
      } else {
        timer.cancel();
      }
    });
  }

  /// Arrête le heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Nettoyage des ressources
  Future<void> _cleanup() async {
    _isConnected = false;
    _isConnecting = false;
    
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}