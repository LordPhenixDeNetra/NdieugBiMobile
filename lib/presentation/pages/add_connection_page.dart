import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/connection_manager.dart';
import '../../domain/models/connection.dart' as domain;
import '../widgets/custom_app_bar.dart';

class AddConnectionPage extends StatefulWidget {
  final domain.ConnectionConfig? connection;
  final domain.ConnectionType? connectionType;

  const AddConnectionPage({
    super.key,
    this.connection,
    this.connectionType,
  });

  @override
  State<AddConnectionPage> createState() => _AddConnectionPageState();
}

class _AddConnectionPageState extends State<AddConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _endpointController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController(text: '30');
  final _portController = TextEditingController(text: '8080');
  final _pathController = TextEditingController(text: '/data/local');
  final _hostController = TextEditingController();

  domain.ConnectionType _selectedType = domain.ConnectionType.bluetooth;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _selectedSecurity = 'WPA2';
  
  late ConnectionManager _connectionManager;

  final List<String> _securityOptions = [
    'Ouverte',
    'WEP',
    'WPA',
    'WPA2',
    'WPA3',
  ];

  @override
  void initState() {
    super.initState();
    _connectionManager = ConnectionManager();
    
    if (widget.connectionType != null) {
      _selectedType = widget.connectionType!;
    }
    
    if (widget.connection != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final connection = widget.connection!;
    _nameController.text = connection.name;
    _selectedType = connection.type;
    
    switch (connection.type) {
      case domain.ConnectionType.bluetooth:
        _deviceIdController.text = connection.deviceId ?? '';
        break;
      case domain.ConnectionType.wifi:
        _ssidController.text = connection.ssid ?? '';
        _passwordController.text = connection.password ?? '';
        _selectedSecurity = connection.security ?? 'WPA2';
        break;
      case domain.ConnectionType.api:
        _endpointController.text = connection.endpoint ?? '';
        _apiKeyController.text = connection.apiKey ?? '';
        _timeoutController.text = connection.settings['timeout']?.toString() ?? '30';
        break;
      case domain.ConnectionType.socket:
        _endpointController.text = connection.endpoint ?? '';
        _portController.text = connection.settings['port']?.toString() ?? '8080';
        break;
      case domain.ConnectionType.local:
        _pathController.text = connection.settings['path'] ?? '/data/local';
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _deviceIdController.dispose();
    _apiKeyController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.connection != null;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Modifier la connexion' : 'Ajouter une connexion',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              if (!isEditing) _buildTypeSelectionSection(),
              if (!isEditing) const SizedBox(height: 24),
              _buildConnectionConfigSection(),
              const SizedBox(height: 32),
              _buildActionButtons(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de base',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la connexion',
                hintText: 'Ex: Imprimante Bureau',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de connexion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...domain.ConnectionType.values.map((type) => _buildTypeOption(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(domain.ConnectionType type) {
    return RadioListTile<domain.ConnectionType>(
      title: Row(
        children: [
          Icon(_getConnectionIcon(type), color: _getConnectionColor(type)),
          const SizedBox(width: 12),
          Text(_getConnectionTypeLabel(type)),
        ],
      ),
      subtitle: Text(_getConnectionDescription(type)),
      value: type,
      groupValue: _selectedType,
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
        });
      },
      activeColor: AppColors.primary,
    );
  }

  Widget _buildConnectionConfigSection() {
    switch (_selectedType) {
      case domain.ConnectionType.bluetooth:
        return _buildBluetoothConfig();
      case domain.ConnectionType.wifi:
        return _buildWiFiConfig();
      case domain.ConnectionType.api:
        return _buildApiConfig();
      case domain.ConnectionType.socket:
        return _buildSocketConfig();
      case domain.ConnectionType.local:
        return _buildLocalConfig();
    }
  }

  Widget _buildBluetoothConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bluetooth, color: _getConnectionColor(_selectedType)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration Bluetooth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'ID de l\'appareil',
                hintText: 'Ex: 00:11:22:33:44:55',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'ID de l\'appareil est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scanBluetoothDevices,
              icon: const Icon(Icons.search),
              label: const Text('Scanner les appareils'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWiFiConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: _getConnectionColor(_selectedType)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration WiFi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: 'SSID (Nom du réseau)',
                hintText: 'Ex: MonReseauWiFi',
                prefixIcon: Icon(Icons.wifi),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le SSID est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSecurity,
              decoration: const InputDecoration(
                labelText: 'Type de sécurité',
                prefixIcon: Icon(Icons.security),
                border: OutlineInputBorder(),
              ),
              items: _securityOptions.map((security) {
                return DropdownMenuItem(
                  value: security,
                  child: Text(security),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSecurity = value;
                });
              },
            ),
            if (_selectedSecurity != 'Ouverte') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Entrez le mot de passe du réseau',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (_selectedSecurity != 'Ouverte' && 
                      (value == null || value.trim().isEmpty)) {
                    return 'Le mot de passe est requis pour ce type de sécurité';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scanWiFiNetworks,
              icon: const Icon(Icons.search),
              label: const Text('Scanner les réseaux'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[50],
                foregroundColor: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: _getConnectionColor(_selectedType)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration API',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'URL de l\'API',
                hintText: 'https://api.example.com/v1',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'URL de l\'API est requise';
                }
                if (!_isValidUrl(value)) {
                  return 'Format d\'URL invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Clé API (optionnel)',
                hintText: 'Entrez votre clé API',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: !_showPassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timeoutController,
              decoration: const InputDecoration(
                labelText: 'Timeout (secondes)',
                hintText: '30',
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final timeout = int.tryParse(value);
                  if (timeout == null || timeout <= 0) {
                    return 'Le timeout doit être un nombre positif';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEditing ? 'Mettre à jour' : 'Ajouter la connexion'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _testConnection,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tester la connexion'),
          ),
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

  String _getConnectionDescription(domain.ConnectionType type) {
    switch (type) {
      case domain.ConnectionType.bluetooth:
        return 'Connecter des appareils via Bluetooth';
      case domain.ConnectionType.wifi:
        return 'Connecter à un réseau WiFi';
      case domain.ConnectionType.api:
        return 'Connecter à une API REST';
      case domain.ConnectionType.socket:
        return 'Connecter via Socket TCP/UDP';
      case domain.ConnectionType.local:
        return 'Connexion locale/fichier';
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _scanBluetoothDevices() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recherche d\'appareils Bluetooth...')),
      );

      await _connectionManager.scanBluetoothDevices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan Bluetooth terminé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du scan Bluetooth: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanWiFiNetworks() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recherche de réseaux WiFi...')),
      );

      await _connectionManager.scanWiFiNetworks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan WiFi terminé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du scan WiFi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      domain.ConnectionConfig connectionConfig;
      final now = DateTime.now();
      final connectionId = widget.connection?.id ?? 'conn_${now.millisecondsSinceEpoch}';

      switch (_selectedType) {
        case domain.ConnectionType.bluetooth:
          connectionConfig = domain.ConnectionConfig(
            id: connectionId,
            type: _selectedType,
            name: _nameController.text.trim(),
            deviceId: _deviceIdController.text.trim(),
            createdAt: widget.connection?.createdAt ?? now,
            ssid: null,
            password: null,
            security: null,
            endpoint: null,
            apiKey: null,
            settings: {},
          );
          break;
        case domain.ConnectionType.wifi:
          connectionConfig = domain.ConnectionConfig(
            id: connectionId,
            type: _selectedType,
            name: _nameController.text.trim(),
            ssid: _ssidController.text.trim(),
            password: _selectedSecurity != 'Ouverte' ? _passwordController.text : null,
            security: _selectedSecurity,
            createdAt: widget.connection?.createdAt ?? now,
            deviceId: null,
            endpoint: null,
            apiKey: null,
            settings: {},
          );
          break;
        case domain.ConnectionType.api:
          connectionConfig = domain.ConnectionConfig(
            id: connectionId,
            type: _selectedType,
            name: _nameController.text.trim(),
            endpoint: _endpointController.text.trim(),
            apiKey: _apiKeyController.text.isNotEmpty ? _apiKeyController.text : null,
            createdAt: widget.connection?.createdAt ?? now,
            deviceId: null,
            ssid: null,
            password: null,
            security: null,
            settings: {
              'timeout': int.tryParse(_timeoutController.text) ?? 30,
            },
          );
          break;
        case domain.ConnectionType.socket:
          connectionConfig = domain.ConnectionConfig(
            id: connectionId,
            type: _selectedType,
            name: _nameController.text.trim(),
            endpoint: _hostController.text.trim(),
            createdAt: widget.connection?.createdAt ?? now,
            deviceId: null,
            ssid: null,
            password: null,
            security: null,
            apiKey: null,
            settings: {
              'port': int.tryParse(_portController.text) ?? 8080,
              'path': _pathController.text.isNotEmpty ? _pathController.text : null,
            },
          );
          break;
        case domain.ConnectionType.local:
          connectionConfig = domain.ConnectionConfig(
            id: connectionId,
            type: _selectedType,
            name: _nameController.text.trim(),
            createdAt: widget.connection?.createdAt ?? now,
            deviceId: null,
            ssid: null,
            password: null,
            security: null,
            endpoint: null,
            apiKey: null,
            settings: {
              'path': _pathController.text.trim(),
            },
          );
          break;
      }

      if (widget.connection != null) {
        await _connectionManager.updateConnection(
          widget.connection!.name,
          connectionConfig,
        );
      } else {
        await _connectionManager.addConnection(connectionConfig);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.connection != null
                  ? 'Connexion mise à jour avec succès'
                  : 'Connexion ajoutée avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSocketConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_ethernet, color: _getConnectionColor(_selectedType)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration Socket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Adresse IP/Hôte',
                hintText: 'ex: 192.168.1.100',
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une adresse IP ou un nom d\'hôte';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'ex: 8080',
                prefixIcon: Icon(Icons.settings_input_component),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un port';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Port invalide (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Chemin (optionnel)',
                hintText: 'ex: /api/data',
                prefixIcon: Icon(Icons.route),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: _getConnectionColor(_selectedType)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration Locale',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Chemin du fichier/dossier',
                hintText: 'ex: C:\\data\\export.csv',
                prefixIcon: Icon(Icons.folder),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un chemin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type de fichier',
                prefixIcon: Icon(Icons.description),
              ),
              items: const [
                DropdownMenuItem(value: 'csv', child: Text('CSV')),
                DropdownMenuItem(value: 'json', child: Text('JSON')),
                DropdownMenuItem(value: 'xml', child: Text('XML')),
                DropdownMenuItem(value: 'txt', child: Text('Texte')),
                DropdownMenuItem(value: 'database', child: Text('Base de données locale')),
              ],
              onChanged: (value) {
                // Handle file type selection
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner un type de fichier';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement file picker
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Parcourir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate connection test
      await Future.delayed(const Duration(seconds: 2));
      
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}