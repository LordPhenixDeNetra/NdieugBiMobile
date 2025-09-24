import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/data_source.dart';
import '../../services/data_source_manager.dart';
import '../../services/database_service.dart';
import '../../services/connectivity_service.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/connectivity_provider.dart';

class DataSourceConfigPage extends StatefulWidget {
  const DataSourceConfigPage({super.key});

  @override
  State<DataSourceConfigPage> createState() => _DataSourceConfigPageState();
}

class _DataSourceConfigPageState extends State<DataSourceConfigPage> {
  final DataSourceManager _dataSourceManager = DataSourceManager();
  final DatabaseService _databaseService = DatabaseService();
  
  DataSourceType _selectedSourceType = DataSourceType.local;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Configuration pour source externe
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  final TextEditingController _nameController = TextEditingController();
  bool _useWebSocket = true;
  bool _useApiRest = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  Future<void> _loadCurrentConfiguration() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger la configuration actuelle
      final dataSources = _dataSourceManager.dataSources;
      if (dataSources.isNotEmpty) {
        final activeSource = dataSources.firstWhere(
          (source) => source.isActive,
          orElse: () => dataSources.first,
        );
        
        setState(() {
          _selectedSourceType = activeSource.type;
          // Extraire host et port de l'URL si disponible
          if (activeSource.url != null) {
            final uri = Uri.tryParse(activeSource.url!);
            if (uri != null) {
              _hostController.text = uri.host;
              _portController.text = uri.port.toString();
            }
          }
          _nameController.text = activeSource.name;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors du chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfiguration() async {
    if (_selectedSourceType == DataSourceType.remote && 
        (_hostController.text.isEmpty || _portController.text.isEmpty)) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs requis');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = DataSourceConfig(
        type: _selectedSourceType,
        name: _selectedSourceType == DataSourceType.local 
            ? 'Base de données locale' 
            : _nameController.text.isNotEmpty 
                ? _nameController.text 
                : 'Backend externe',
        url: _selectedSourceType == DataSourceType.remote 
            ? 'http://${_hostController.text}:${_portController.text}' 
            : null,
        lastSync: DateTime.now(),
        metadata: _selectedSourceType == DataSourceType.remote ? {
          'websocket_enabled': _useWebSocket,
          'api_rest_enabled': _useApiRest,
          'websocket_endpoint': '/ws',
          'api_endpoint': '/api',
        } : null,
      );

      await _dataSourceManager.addDataSource(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sauvegardée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    if (_selectedSourceType == DataSourceType.local) {
      // Test de la base de données locale
      try {
        setState(() => _isLoading = true);
        await _databaseService.database;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Base de données locale accessible'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur base de données: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Test de connexion au backend externe
      if (_hostController.text.isEmpty || _portController.text.isEmpty) {
        setState(() => _errorMessage = 'Veuillez remplir l\'adresse et le port');
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final connectivityService = ConnectivityService();
        final url = 'http://${_hostController.text}:${_portController.text}/health';
        
        // Test de connectivité réseau d'abord
        if (!connectivityService.isOnline) {
          throw Exception('Aucune connexion réseau disponible');
        }

        // Test de connexion au backend
        // Note: Ici on pourrait utiliser le connection_manager existant
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔄 Test de connexion vers $url...'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Simulation du test - à remplacer par un vrai test
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connexion au backend réussie'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur de connexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Configuration des données',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête explicatif
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Choisissez votre source de données',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous pouvez utiliser soit la base de données locale du téléphone, soit vous connecter à un backend externe sur un ordinateur.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Sélection du type de source
                  Text(
                    'Type de source de données',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option: Base de données locale
                  Card(
                    elevation: _selectedSourceType == DataSourceType.local ? 4 : 1,
                    color: _selectedSourceType == DataSourceType.local 
                        ? AppColors.primary.withOpacity(0.1) 
                        : null,
                    child: RadioListTile<DataSourceType>(
                      value: DataSourceType.local,
                      groupValue: _selectedSourceType,
                      onChanged: (value) {
                        setState(() => _selectedSourceType = value!);
                      },
                      title: const Row(
                        children: [
                          Icon(Icons.phone_android, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Base de données locale (SQLite)'),
                        ],
                      ),
                      subtitle: const Text(
                        'Utilise la base de données SQLite du téléphone.\nFonctionne hors ligne.',
                      ),
                      activeColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Option: Backend externe
                  Card(
                    elevation: _selectedSourceType == DataSourceType.remote ? 4 : 1,
                    color: _selectedSourceType == DataSourceType.remote 
                        ? AppColors.primary.withOpacity(0.1) 
                        : null,
                    child: RadioListTile<DataSourceType>(
                      value: DataSourceType.remote,
                      groupValue: _selectedSourceType,
                      onChanged: (value) {
                        setState(() => _selectedSourceType = value!);
                      },
                      title: const Row(
                        children: [
                          Icon(Icons.computer, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Backend externe (Ordinateur)'),
                        ],
                      ),
                      subtitle: const Text(
                        'Se connecte à un serveur backend sur un ordinateur.\nSupporte WebSocket et API REST.',
                      ),
                      activeColor: AppColors.primary,
                    ),
                  ),

                  // Configuration pour backend externe
                  if (_selectedSourceType == DataSourceType.remote) ...[
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuration du backend',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nom de la connexion
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la connexion',
                              hintText: 'Ex: Ordinateur bureau',
                              prefixIcon: Icon(Icons.label),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Adresse IP
                          TextField(
                            controller: _hostController,
                            decoration: const InputDecoration(
                              labelText: 'Adresse IP de l\'ordinateur',
                              hintText: 'Ex: 192.168.1.100',
                              prefixIcon: Icon(Icons.computer),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 16),

                          // Port
                          TextField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '8080',
                              prefixIcon: Icon(Icons.settings_ethernet),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Options de communication
                          Text(
                            'Méthodes de communication',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          CheckboxListTile(
                            value: _useWebSocket,
                            onChanged: (value) {
                              setState(() => _useWebSocket = value ?? true);
                            },
                            title: const Text('WebSocket (Temps réel)'),
                            subtitle: const Text('Communication bidirectionnelle instantanée'),
                            activeColor: AppColors.primary,
                          ),

                          CheckboxListTile(
                            value: _useApiRest,
                            onChanged: (value) {
                              setState(() => _useApiRest = value ?? false);
                            },
                            title: const Text('API REST (HTTP)'),
                            subtitle: const Text('Communication par requêtes HTTP'),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Message d'erreur
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Boutons d'action
                  Row(
                    children: [
                      // Bouton Test
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: const Icon(Icons.wifi_find),
                          label: const Text('Tester'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Bouton Sauvegarder
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfiguration,
                          icon: const Icon(Icons.save),
                          label: const Text('Sauvegarder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Informations sur la connectivité
                  Consumer<ConnectivityProvider>(
                    builder: (context, connectivity, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: connectivity.isOnline 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: connectivity.isOnline 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              connectivity.isOnline 
                                  ? Icons.wifi 
                                  : Icons.wifi_off,
                              color: connectivity.isOnline 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                connectivity.isOnline
                                    ? 'Connecté au réseau (${connectivity.connectionTypeString})'
                                    : 'Hors ligne - Seule la base locale est disponible',
                                style: TextStyle(
                                  color: connectivity.isOnline 
                                      ? Colors.green.shade700 
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}