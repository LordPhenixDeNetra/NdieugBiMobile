import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../pages/settings_page.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.themeMode == ThemeMode.dark ||
              (themeProvider.themeMode == ThemeMode.system && 
               MediaQuery.of(context).platformBrightness == Brightness.dark);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDark),
                const SizedBox(height: 30),
                _buildAppInfo(context, isDark),
                const SizedBox(height: 30),
                _buildMainOptions(context, isDark),
                const SizedBox(height: 30),
                _buildSettings(context, isDark, themeProvider),
                const SizedBox(height: 30),
                _buildSupport(context, isDark),
                const SizedBox(height: 30),
                _buildAbout(context, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? AppColors.darkGradientPrimary
            : AppColors.lightGradientPrimary,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.store,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NdieugBi',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestion commerciale moderne',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context, bool isDark) {
    return _buildSection(
      context,
      title: 'Informations de l\'application',
      isDark: isDark,
      children: [
        _buildInfoTile(
          context,
          icon: Icons.info_outline,
          title: 'Version',
          subtitle: '1.0.0',
          color: AppColors.info,
          isDark: isDark,
        ),
        _buildInfoTile(
          context,
          icon: Icons.update,
          title: 'Dernière mise à jour',
          subtitle: 'Aujourd\'hui',
          color: AppColors.success,
          isDark: isDark,
        ),
        _buildInfoTile(
          context,
          icon: Icons.storage,
          title: 'Base de données',
          subtitle: 'SQLite locale',
          color: AppColors.accentBlue,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMainOptions(BuildContext context, bool isDark) {
    return _buildSection(
      context,
      title: 'Options principales',
      isDark: isDark,
      children: [
        _buildMenuTile(
          context,
          icon: Icons.dashboard,
          title: 'Tableau de bord',
          subtitle: 'Vue d\'ensemble des activités',
          color: AppColors.accentPurple,
          isDark: isDark,
          onTap: () => Navigator.of(context).pop(),
        ),
        _buildMenuTile(
          context,
          icon: Icons.inventory_2,
          title: 'Gestion des produits',
          subtitle: 'Ajouter, modifier, supprimer des produits',
          color: AppColors.accentGreen,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            // Navigation vers les produits sera ajoutée
          },
        ),
        _buildMenuTile(
          context,
          icon: Icons.receipt_long,
          title: 'Factures',
          subtitle: 'Gérer les factures et devis',
          color: AppColors.accentOrange,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            // Navigation vers les factures sera ajoutée
          },
        ),
        _buildMenuTile(
          context,
          icon: Icons.point_of_sale,
          title: 'Caisse',
          subtitle: 'Interface de vente rapide',
          color: AppColors.accentRose,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).pop();
            // Navigation vers la caisse sera ajoutée
          },
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, bool isDark, ThemeProvider themeProvider) {
    return _buildSection(
      context,
      title: 'Paramètres',
      isDark: isDark,
      children: [
        _buildMenuTile(
          context,
          icon: Icons.settings,
          title: 'Paramètres avancés',
          subtitle: 'Gestion des données, connexions et plus',
          color: AppColors.primary,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          },
        ),
        _buildSettingTile(
          context,
          icon: isDark ? Icons.light_mode : Icons.dark_mode,
          title: 'Thème',
          subtitle: isDark ? 'Mode sombre activé' : 'Mode clair activé',
          color: isDark ? AppColors.warning : AppColors.info,
          isDark: isDark,
          trailing: Switch(
            value: isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: AppColors.primaryLight,
          ),
        ),
        _buildMenuTile(
          context,
          icon: Icons.language,
          title: 'Langue',
          subtitle: 'Français',
          color: AppColors.accentBlue,
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité à venir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildMenuTile(
          context,
          icon: Icons.backup,
          title: 'Sauvegarde',
          subtitle: 'Exporter les données',
          color: AppColors.success,
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité à venir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupport(BuildContext context, bool isDark) {
    return _buildSection(
      context,
      title: 'Support',
      isDark: isDark,
      children: [
        _buildMenuTile(
          context,
          icon: Icons.help_outline,
          title: 'Aide',
          subtitle: 'Guide d\'utilisation',
          color: AppColors.info,
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Guide d\'aide à venir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildMenuTile(
          context,
          icon: Icons.bug_report,
          title: 'Signaler un problème',
          subtitle: 'Nous aider à améliorer l\'app',
          color: AppColors.warning,
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Système de rapport à venir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildMenuTile(
          context,
          icon: Icons.contact_support,
          title: 'Nous contacter',
          subtitle: 'Support technique',
          color: AppColors.accentRose,
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Informations de contact à venir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAbout(BuildContext context, bool isDark) {
    return _buildSection(
      context,
      title: 'À propos',
      isDark: isDark,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.copyright,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NdieugBi © 2024',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Application de gestion commerciale moderne et intuitive, conçue pour simplifier la gestion de votre commerce.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.code,
                    color: AppColors.accentPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Développé avec Flutter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: trailing,
    );
  }
}