import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/data_source.dart';
import '../../services/data_source_manager.dart';
import '../widgets/custom_app_bar.dart';
import 'add_data_source_page.dart';

class DataSourcesPage extends StatefulWidget {
  const DataSourcesPage({super.key});

  @override
  State<DataSourcesPage> createState() => _DataSourcesPageState();
}

class _DataSourcesPageState extends State<DataSourcesPage> {
  late DataSourceManager _dataSourceManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDataSources();
  }

  Future<void> _initializeDataSources() async {
    _dataSourceManager = DataSourceManager();
    await _dataSourceManager.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Sources de données',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddDataSource(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDataSources,
              child: _buildDataSourcesList(),
            ),
    );
  }

  Widget _buildDataSourcesList() {
    final dataSources = _dataSourceManager.dataSources;

    if (dataSources.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: dataSources.length,
      itemBuilder: (context, index) {
        final dataSource = dataSources[index];
        return _buildDataSourceCard(dataSource);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune source de données',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première source de données\npour commencer la synchronisation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddDataSource(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une source'),
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

  Widget _buildDataSourceCard(DataSourceConfig dataSource) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                    color: _getDataSourceColor(dataSource.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDataSourceIcon(dataSource.type),
                    color: _getDataSourceColor(dataSource.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataSource.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getDataSourceTypeLabel(dataSource.type),
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
                    color: dataSource.isActive ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dataSource.isActive ? 'Actif' : 'Inactif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, dataSource),
                  itemBuilder: (context) => [
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
                      value: 'sync',
                      child: Row(
                        children: [
                          Icon(Icons.sync, size: 20),
                          SizedBox(width: 8),
                          Text('Synchroniser'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.power_settings_new, size: 20),
                          SizedBox(width: 8),
                          Text('Activer/Désactiver'),
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
            if (dataSource.url != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dataSource.url!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Dernière sync: ${_formatDateTime(dataSource.lastSync)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  Future<void> _navigateToAddDataSource() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDataSourcePage()),
    );

    if (result == true) {
      await _refreshDataSources();
    }
  }

  Future<void> _refreshDataSources() async {
    await _dataSourceManager.loadDataSources();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleMenuAction(String action, DataSourceConfig dataSource) async {
    switch (action) {
      case 'edit':
        await _editDataSource(dataSource);
        break;
      case 'sync':
        await _syncDataSource(dataSource);
        break;
      case 'toggle':
        await _toggleDataSource(dataSource);
        break;
      case 'delete':
        await _deleteDataSource(dataSource);
        break;
    }
  }

  Future<void> _editDataSource(DataSourceConfig dataSource) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDataSourcePage(dataSource: dataSource),
      ),
    );

    if (result == true) {
      await _refreshDataSources();
    }
  }

  Future<void> _syncDataSource(DataSourceConfig dataSource) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation en cours...')),
      );

      await _dataSourceManager.syncDataSource(dataSource.type);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronisation terminée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshDataSources();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleDataSource(DataSourceConfig dataSource) async {
    try {
      final updatedConfig = DataSourceConfig(
        type: dataSource.type,
        name: dataSource.name,
        url: dataSource.url,
        headers: dataSource.headers,
        credentials: dataSource.credentials,
        isActive: !dataSource.isActive,
        lastSync: dataSource.lastSync,
        metadata: dataSource.metadata,
      );

      await _dataSourceManager.updateDataSource(dataSource.name, updatedConfig);
      await _refreshDataSources();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedConfig.isActive 
                  ? 'Source de données activée' 
                  : 'Source de données désactivée'
            ),
          ),
        );
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
    }
  }

  Future<void> _deleteDataSource(DataSourceConfig dataSource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la source de données "${dataSource.name}" ?'
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
        await _dataSourceManager.removeDataSource(dataSource.name);
        await _refreshDataSources();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Source de données supprimée'),
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
}