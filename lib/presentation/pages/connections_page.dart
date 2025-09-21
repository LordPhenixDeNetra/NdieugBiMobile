import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/connection.dart' as domain;
import '../../services/connection_manager.dart' as service;
import '../widgets/custom_app_bar.dart';
import 'add_connection_page.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late service.ConnectionManager _connectionManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeConnections();
  }

  Future<void> _initializeConnections() async {
    _connectionManager = service.ConnectionManager();
    await _connectionManager.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Connexions',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
            Tab(icon: Icon(Icons.wifi), text: 'WiFi'),
            Tab(icon: Icon(Icons.api), text: 'API'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddConnection(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBluetoothTab(),
                _buildWiFiTab(),
                _buildApiTab(),
              ],
            ),
    );
  }

  Widget _buildBluetoothTab() {
    return RefreshIndicator(
      onRefresh: _refreshBluetoothConnections,
      child: _buildConnectionsList(domain.ConnectionType.bluetooth),
    );
  }

  Widget _buildWiFiTab() {
    return RefreshIndicator(
      onRefresh: _refreshWiFiConnections,
      child: _buildConnectionsList(domain.ConnectionType.wifi),
    );
  }

  Widget _buildApiTab() {
    return RefreshIndicator(
      onRefresh: _refreshApiConnections,
      child: _buildConnectionsList(domain.ConnectionType.api),
    );
  }

  Widget _buildConnectionsList(domain.ConnectionType type) {
    final connections = _connectionManager.getConnectionsByType(type);

    if (connections.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connectionInfo = connections[index];
        return _buildConnectionCard(connectionInfo);
      },
    );
  }

  Widget _buildEmptyState(domain.ConnectionType type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case domain.ConnectionType.bluetooth:
        title = 'Aucune connexion Bluetooth';
        subtitle = 'Ajoutez des appareils Bluetooth\npour la synchronisation des données';
        icon = Icons.bluetooth_disabled;
        break;
      case domain.ConnectionType.wifi:
        title = 'Aucune connexion WiFi';
        subtitle = 'Configurez des connexions WiFi\npour accéder aux données réseau';
        icon = Icons.wifi_off;
        break;
      case domain.ConnectionType.api:
        title = 'Aucune connexion API';
        subtitle = 'Ajoutez des connexions API\npour synchroniser avec des services externes';
        icon = Icons.api;
        break;
      case domain.ConnectionType.socket:
        title = 'Aucune connexion Socket';
        subtitle = 'Configurez des connexions Socket\npour la communication en temps réel';
        icon = Icons.settings_ethernet;
        break;
      case domain.ConnectionType.local:
        title = 'Aucune connexion locale';
        subtitle = 'Configurez des connexions locales\npour accéder aux données hors ligne';
        icon = Icons.storage;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddConnection(type),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une connexion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(service.ConnectionInfo connectionInfo) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final connection = connectionInfo.config;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getConnectionColor(connection.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getConnectionIcon(connection.type),
                    color: _getConnectionColor(connection.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getConnectionTypeLabel(connection.type),
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConnectionStatusColor(connectionInfo.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getConnectionStatusLabel(connectionInfo.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, connectionInfo),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'connect',
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 20),
                          SizedBox(width: 8),
                          Text('Se connecter'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off, size: 20),
                          SizedBox(width: 8),
                          Text('Se déconnecter'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'test',
                      child: Row(
                        children: [
                          Icon(Icons.speed, size: 20),
                          SizedBox(width: 8),
                          Text('Tester'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildConnectionDetails(_convertToDomainConfig(connectionInfo.config)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDetails(domain.ConnectionConfig connection) {
    switch (connection.type) {
      case domain.ConnectionType.bluetooth:
        return _buildBluetoothDetails(connection);
      case domain.ConnectionType.wifi:
        return _buildWiFiDetails(connection);
      case domain.ConnectionType.api:
        return _buildApiDetails(connection);
      case domain.ConnectionType.socket:
        return _buildSocketDetails(connection);
      case domain.ConnectionType.local:
        return _buildLocalDetails(connection);
    }
  }

  Widget _buildBluetoothDetails(domain.ConnectionConfig connection) {
    return Column(
      children: [
        if (connection.deviceId != null) ...[
          Row(
            children: [
              Icon(Icons.devices, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'ID: ${connection.deviceId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.signal_cellular_alt, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Force du signal: ${connection.signalStrength ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWiFiDetails(domain.ConnectionConfig connection) {
    return Column(
      children: [
        if (connection.ssid != null) ...[
          Row(
            children: [
              Icon(Icons.wifi, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'SSID: ${connection.ssid}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.security, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Sécurité: ${connection.security ?? 'Ouverte'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiDetails(domain.ConnectionConfig connection) {
    return Column(
      children: [
        if (connection.endpoint != null) ...[
          Row(
            children: [
              Icon(Icons.link, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  connection.endpoint!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Timeout: ${connection.settings['timeout'] ?? 30}s',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocketDetails(domain.ConnectionConfig connection) {
    return Column(
      children: [
        if (connection.endpoint != null) ...[
          Row(
            children: [
              Icon(Icons.settings_ethernet, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  connection.endpoint!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Port: ${connection.settings['port'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocalDetails(domain.ConnectionConfig connection) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.storage, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Stockage local',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.folder, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Chemin: ${connection.settings['path'] ?? '/data/local'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getConnectionIcon(domain.ConnectionType type) {
    switch (type) {
      case domain.ConnectionType.bluetooth:
        return Icons.bluetooth;
      case domain.ConnectionType.wifi:
        return Icons.wifi;
      case domain.ConnectionType.api:
        return Icons.api;
      case domain.ConnectionType.socket:
        return Icons.settings_ethernet;
      case domain.ConnectionType.local:
        return Icons.storage;
    }
  }

  Color _getConnectionColor(domain.ConnectionType type) {
    switch (type) {
      case domain.ConnectionType.bluetooth:
        return Colors.indigo;
      case domain.ConnectionType.wifi:
        return Colors.teal;
      case domain.ConnectionType.api:
        return Colors.purple;
      case domain.ConnectionType.socket:
        return Colors.orange;
      case domain.ConnectionType.local:
        return Colors.green;
    }
  }

  String _getConnectionTypeLabel(domain.ConnectionType type) {
    switch (type) {
      case domain.ConnectionType.bluetooth:
        return 'Connexion Bluetooth';
      case domain.ConnectionType.wifi:
        return 'Connexion WiFi';
      case domain.ConnectionType.api:
        return 'Connexion API';
      case domain.ConnectionType.socket:
        return 'Connexion Socket';
      case domain.ConnectionType.local:
        return 'Connexion Locale';
    }
  }

  Color _getConnectionStatusColor(domain.ConnectionStatus status) {
    switch (status) {
      case domain.ConnectionStatus.connected:
        return Colors.green;
      case domain.ConnectionStatus.disconnected:
        return Colors.red;
      case domain.ConnectionStatus.connecting:
        return Colors.orange;
      case domain.ConnectionStatus.failed:
        return Colors.red;
      case domain.ConnectionStatus.unknown:
        return Colors.grey;
    }
  }

  String _getConnectionStatusLabel(domain.ConnectionStatus status) {
    switch (status) {
      case domain.ConnectionStatus.connected:
        return 'Connecté';
      case domain.ConnectionStatus.disconnected:
        return 'Déconnecté';
      case domain.ConnectionStatus.connecting:
        return 'Connexion...';
      case domain.ConnectionStatus.failed:
        return 'Erreur';
      case domain.ConnectionStatus.unknown:
        return 'Inconnu';
    }
  }

  Future<void> _navigateToAddConnection([domain.ConnectionType? type]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddConnectionPage(connectionType: type),
      ),
    );

    if (result == true) {
      await _refreshConnections();
    }
  }

  Future<void> _refreshConnections() async {
    await _connectionManager.refreshConnections();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshBluetoothConnections() async {
    await _connectionManager.scanBluetoothDevices();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshWiFiConnections() async {
    await _connectionManager.scanWiFiNetworks();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshApiConnections() async {
    await _connectionManager.testApiConnections();
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMenuAction(String action, service.ConnectionInfo connectionInfo) async {
    final connection = _convertToDomainConfig(connectionInfo.config);
    switch (action) {
      case 'connect':
        await _connectToDevice(connection);
        break;
      case 'disconnect':
        await _disconnectFromDevice(connection);
        break;
      case 'edit':
        await _editConnection(connection);
        break;
      case 'test':
        await _testConnection(connection);
        break;
      case 'delete':
        await _deleteConnection(connection);
        break;
    }
  }

  Future<void> _connectToDevice(domain.ConnectionConfig connection) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion en cours...')),
      );

      await _connectionManager.connect(connection.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion établie avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectFromDevice(domain.ConnectionConfig connection) async {
    try {
      await _connectionManager.disconnect(connection.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion réussie'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editConnection(domain.ConnectionConfig connection) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddConnectionPage(connection: connection),
      ),
    );

    if (result == true) {
      await _refreshConnections();
    }
  }

  Future<void> _testConnection(domain.ConnectionConfig connection) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test de connexion en cours...')),
      );

      await _connectionManager.testConnection(connection.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test de connexion réussi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec du test de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteConnection(domain.ConnectionConfig connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la connexion "${connection.name}" ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _connectionManager.removeConnection(connection.name);
        await _refreshConnections();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Convert ServiceConnectionConfig to domain.ConnectionConfig
  domain.ConnectionConfig _convertToDomainConfig(service.ServiceConnectionConfig serviceConfig) {
    return domain.ConnectionConfig(
      id: serviceConfig.settings['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: serviceConfig.name,
      type: serviceConfig.type, // Direct assignment since ServiceConnectionConfig uses domain.ConnectionType
      settings: serviceConfig.settings,
      isActive: serviceConfig.settings['isActive'] ?? false,
      createdAt: serviceConfig.settings['createdAt'] != null 
          ? DateTime.parse(serviceConfig.settings['createdAt'])
          : DateTime.now(),
      lastConnected: serviceConfig.settings['lastConnected'] != null 
          ? DateTime.parse(serviceConfig.settings['lastConnected'])
          : null,
      deviceId: serviceConfig.settings['deviceId'],
      ssid: serviceConfig.settings['ssid'],
      password: serviceConfig.settings['password'],
      security: serviceConfig.settings['security'],
      endpoint: serviceConfig.endpoint,
      apiKey: serviceConfig.apiKey,
      signalStrength: serviceConfig.settings['signalStrength'],
    );
  }
}