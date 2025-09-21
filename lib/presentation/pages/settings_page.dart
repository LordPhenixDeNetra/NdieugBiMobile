import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'data_sources_page.dart';
import 'connections_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Paramètres',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Gestion des données'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.storage,
            title: 'Sources de données',
            subtitle: 'Gérer les sources de données (SQLite, Excel, API, etc.)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DataSourcesPage()),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.wifi,
            title: 'Connexions',
            subtitle: 'Configurer les connexions Bluetooth, WiFi et API',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConnectionsPage()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Synchronisation'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.sync,
            title: 'Synchronisation automatique',
            subtitle: 'Configurer la synchronisation des données',
            onTap: () {
              // TODO: Implémenter la page de configuration de synchronisation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Application'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.palette,
            title: 'Thème',
            subtitle: 'Changer l\'apparence de l\'application',
            onTap: () {
              // TODO: Implémenter la page de configuration du thème
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Changer la langue de l\'application',
            onTap: () {
              // TODO: Implémenter la page de configuration de langue
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('À propos'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            icon: Icons.info,
            title: 'Informations',
            subtitle: 'Version de l\'application et crédits',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'NdieugBi',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.store,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('Application de gestion commerciale moderne et intuitive.'),
        const SizedBox(height: 16),
        const Text('Développé avec Flutter et Dart.'),
      ],
    );
  }
}