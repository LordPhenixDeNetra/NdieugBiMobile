import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/home_screen_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/animated_home_wrapper.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedHomeWrapper(
      child: Consumer<HomeScreenProvider>(
        builder: (context, homeProvider, child) {
          return Scaffold(
            body: Column(
              children: [
                const CustomAppBar(),
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivityProvider, child) {
                    return ConnectivityBanner(
                      status: connectivityProvider.status,
                      onRetry: () => connectivityProvider.checkConnectivity(),
                    );
                  },
                ),
                Expanded(
                  child: _buildDashboard(context, homeProvider),
                ),
              ],
            ),
            floatingActionButton: const ThemeToggleButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, HomeScreenProvider homeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 30),
          _buildQuickStats(context),
          const SizedBox(height: 30),
          _buildQuickActions(context, homeProvider),
          const SizedBox(height: 30),
          _buildRecentActivity(context, homeProvider),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [AppColors.primaryDark, AppColors.accentPurple.withValues(alpha: 0.8)]
            : [AppColors.primaryLight, AppColors.accentBlue.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Bienvenue !',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez votre point de vente avec facilité',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, child) {
              return Row(
                children: [
                  Icon(
                    connectivity.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connectivity.statusMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu rapide',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.inventory_2,
                title: 'Produits',
                value: '1,234',
                subtitle: 'En stock',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.shopping_cart,
                title: 'Ventes',
                value: '89',
                subtitle: 'Aujourd\'hui',
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.attach_money,
                title: 'Revenus',
                value: '125,450 F',
                subtitle: 'Ce mois',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.trending_up,
                title: 'Croissance',
                value: '+12%',
                subtitle: 'vs mois dernier',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert,
                color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, HomeScreenProvider homeProvider) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              context,
              icon: Icons.add_shopping_cart,
              title: 'Nouvelle Vente',
              subtitle: 'Créer une transaction',
              color: AppColors.primaryLight,
              onTap: () => homeProvider.navigateToSales(context),
            ),
            _buildActionCard(
              context,
              icon: Icons.inventory,
              title: 'Inventaire',
              subtitle: 'Gérer les produits',
              color: AppColors.info,
              onTap: () => homeProvider.navigateToInventory(context),
            ),
            _buildActionCard(
              context,
              icon: Icons.receipt_long,
              title: 'Factures',
              subtitle: 'Voir les transactions',
              color: AppColors.warning,
              onTap: () => homeProvider.navigateToInvoices(context),
            ),
            _buildActionCard(
              context,
              icon: Icons.analytics,
              title: 'Rapports',
              subtitle: 'Analyser les données',
              color: AppColors.success,
              onTap: () => homeProvider.navigateToReports(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, HomeScreenProvider homeProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => homeProvider.navigateToActivity(context),
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                icon: Icons.shopping_cart,
                title: 'Nouvelle vente',
                subtitle: 'Facture #1234 - 15,500 F',
                time: 'Il y a 5 min',
                color: AppColors.success,
              ),
              _buildDivider(context),
              _buildActivityItem(
                context,
                icon: Icons.inventory_2,
                title: 'Stock mis à jour',
                subtitle: 'Produit: Coca Cola 33cl',
                time: 'Il y a 12 min',
                color: AppColors.info,
              ),
              _buildDivider(context),
              _buildActivityItem(
                context,
                icon: Icons.warning,
                title: 'Stock faible',
                subtitle: 'Produit: Pain de mie',
                time: 'Il y a 1h',
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Divider(
      height: 1,
      color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurface).withValues(alpha: 0.1),
    );
  }
}