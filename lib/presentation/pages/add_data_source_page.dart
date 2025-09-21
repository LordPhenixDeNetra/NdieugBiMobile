import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/data_source.dart';
import '../../services/data_source_manager.dart';
import '../widgets/custom_app_bar.dart';

class AddDataSourcePage extends StatefulWidget {
  final DataSourceConfig? dataSource;

  const AddDataSourcePage({super.key, this.dataSource});

  @override
  State<AddDataSourcePage> createState() => _AddDataSourcePageState();
}

class _AddDataSourcePageState extends State<AddDataSourcePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyController = TextEditingController();
  
  DataSourceType _selectedType = DataSourceType.local;
  bool _isActive = true;
  bool _isLoading = false;
  bool _showPassword = false;
  
  late DataSourceManager _dataSourceManager;

  @override
  void initState() {
    super.initState();
    _dataSourceManager = DataSourceManager();
    
    if (widget.dataSource != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final dataSource = widget.dataSource!;
    _nameController.text = dataSource.name;
    _urlController.text = dataSource.url ?? '';
    _selectedType = dataSource.type;
    _isActive = dataSource.isActive;
    
    if (dataSource.credentials != null) {
      _usernameController.text = dataSource.credentials!['username'] ?? '';
      _passwordController.text = dataSource.credentials!['password'] ?? '';
      _apiKeyController.text = dataSource.credentials!['apiKey'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.dataSource != null;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Modifier la source' : 'Ajouter une source',
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
              _buildTypeSelectionSection(),
              const SizedBox(height: 24),
              if (_requiresUrl()) _buildUrlSection(),
              if (_requiresCredentials()) _buildCredentialsSection(),
              const SizedBox(height: 24),
              _buildAdvancedOptionsSection(),
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
                labelText: 'Nom de la source',
                hintText: 'Ex: Base de données principale',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text('Source active'),
              ],
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
              'Type de source de données',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...DataSourceType.values.map((type) => _buildTypeOption(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(DataSourceType type) {
    return RadioListTile<DataSourceType>(
      title: Row(
        children: [
          Icon(_getDataSourceIcon(type), color: _getDataSourceColor(type)),
          const SizedBox(width: 12),
          Text(_getDataSourceTypeLabel(type)),
        ],
      ),
      subtitle: Text(_getDataSourceDescription(type)),
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

  Widget _buildUrlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration de connexion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _getUrlLabel(),
                hintText: _getUrlHint(),
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (_requiresUrl() && (value == null || value.trim().isEmpty)) {
                  return 'L\'URL est requise pour ce type de source';
                }
                if (value != null && value.isNotEmpty && !_isValidUrl(value)) {
                  return 'Format d\'URL invalide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authentification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedType == DataSourceType.api) ...[
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'Clé API',
                  hintText: 'Entrez votre clé API',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                obscureText: !_showPassword,
              ),
            ] else ...[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  hintText: 'Entrez votre nom d\'utilisateur',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Entrez votre mot de passe',
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options avancées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Synchronisation automatique'),
              subtitle: const Text('Synchroniser automatiquement les données'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement auto sync toggle
                },
                activeColor: AppColors.primary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Intervalle de synchronisation'),
              subtitle: const Text('Toutes les 30 minutes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show sync interval picker
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
            onPressed: _isLoading ? null : _saveDataSource,
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
                : Text(isEditing ? 'Mettre à jour' : 'Ajouter la source'),
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

  bool _requiresUrl() {
    return _selectedType == DataSourceType.cloud ||
           _selectedType == DataSourceType.api;
  }

  bool _requiresCredentials() {
    return _selectedType == DataSourceType.cloud ||
           _selectedType == DataSourceType.api;
  }

  String _getUrlLabel() {
    switch (_selectedType) {
      case DataSourceType.cloud:
        return 'URL Google Sheets';
      case DataSourceType.api:
        return 'URL de l\'API';
      default:
        return 'URL';
    }
  }

  String _getUrlHint() {
    switch (_selectedType) {
      case DataSourceType.cloud:
        return 'https://docs.google.com/spreadsheets/d/...';
      case DataSourceType.api:
        return 'https://api.example.com/v1';
      default:
        return 'https://example.com';
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

  IconData _getDataSourceIcon(DataSourceType type) {
    switch (type) {
      case DataSourceType.local:
        return Icons.storage;
      case DataSourceType.file:
        return Icons.table_chart;
      case DataSourceType.cloud:
        return Icons.cloud;
      case DataSourceType.api:
        return Icons.api;
      case DataSourceType.database:
        return Icons.bluetooth;
      case DataSourceType.remote:
        return Icons.wifi;
      case DataSourceType.cache:
        return Icons.cached;
    }
  }

  Color _getDataSourceColor(DataSourceType type) {
    switch (type) {
      case DataSourceType.local:
        return Colors.blue;
      case DataSourceType.file:
        return Colors.green;
      case DataSourceType.cloud:
        return Colors.orange;
      case DataSourceType.api:
        return Colors.purple;
      case DataSourceType.database:
        return Colors.indigo;
      case DataSourceType.remote:
        return Colors.teal;
      case DataSourceType.cache:
        return Colors.grey;
    }
  }

  String _getDataSourceTypeLabel(DataSourceType type) {
    switch (type) {
      case DataSourceType.local:
        return 'Base de données locale';
      case DataSourceType.file:
        return 'Fichier Excel';
      case DataSourceType.cloud:
        return 'Google Sheets';
      case DataSourceType.api:
        return 'API Cloud';
      case DataSourceType.database:
        return 'Connexion Bluetooth';
      case DataSourceType.remote:
        return 'Connexion WiFi';
      case DataSourceType.cache:
        return 'Cache local';
    }
  }

  String _getDataSourceDescription(DataSourceType type) {
    switch (type) {
      case DataSourceType.local:
        return 'Stockage local sur l\'appareil';
      case DataSourceType.file:
        return 'Fichier Excel (.xlsx, .xls)';
      case DataSourceType.cloud:
        return 'Feuille de calcul Google en ligne';
      case DataSourceType.api:
        return 'API REST dans le cloud';
      case DataSourceType.database:
        return 'Appareil connecté via Bluetooth';
      case DataSourceType.remote:
        return 'Appareil connecté via WiFi';
      case DataSourceType.cache:
        return 'Cache temporaire local';
    }
  }

  Future<void> _saveDataSource() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credentials = <String, String>{};
      
      if (_requiresCredentials()) {
        if (_selectedType == DataSourceType.api) {
          if (_apiKeyController.text.isNotEmpty) {
            credentials['apiKey'] = _apiKeyController.text;
          }
        } else {
          if (_usernameController.text.isNotEmpty) {
            credentials['username'] = _usernameController.text;
          }
          if (_passwordController.text.isNotEmpty) {
            credentials['password'] = _passwordController.text;
          }
        }
      }

      final dataSourceConfig = DataSourceConfig(
        type: _selectedType,
        name: _nameController.text.trim(),
        url: _requiresUrl() ? _urlController.text.trim() : null,
        headers: {},
        credentials: credentials.isNotEmpty ? credentials : null,
        isActive: _isActive,
        lastSync: DateTime.now(),
        metadata: {},
      );

      if (widget.dataSource != null) {
        await _dataSourceManager.updateDataSource(
          widget.dataSource!.name,
          dataSourceConfig,
        );
      } else {
        await _dataSourceManager.addDataSource(dataSourceConfig);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.dataSource != null
                  ? 'Source de données mise à jour avec succès'
                  : 'Source de données ajoutée avec succès',
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
            content: Text('Connexion testée avec succès'),
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