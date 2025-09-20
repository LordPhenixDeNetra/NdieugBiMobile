import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/connectivity_service.dart';
import '../providers/theme_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/theme_toggle_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ThemeProvider, AppProvider>(
        builder: (context, themeProvider, appProvider, child) {
          return Column(
            children: [
              const CustomAppBar(),
              if (!appProvider.isOnline) ConnectivityBanner(
                status: appProvider.isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline,
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildMainContent(context, themeProvider, appProvider),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: const ThemeToggleButton(),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeProvider themeProvider, AppProvider appProvider) {
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system && 
         MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? AppColors.darkGradientPrimary
            : AppColors.lightGradientPrimary,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context, isDark),
              const SizedBox(height: 32),
              _buildQuickActions(context, isDark),
              const SizedBox(height: 32),
              _buildStatusCards(context, appProvider, isDark),
              const Spacer(),
              _buildFooter(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenue dans',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark 
              ? [AppColors.darkAccentPrimary, AppColors.darkAccentSecondary]
              : [AppColors.lightAccentPrimary, AppColors.lightAccentSecondary],
          ).createShader(bounds),
          child: Text(
            'NdieugBi',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Votre solution complète de gestion commerciale',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      {'icon': Icons.qr_code_scanner, 'title': 'Scanner', 'color': AppColors.lightAccentPrimary},
      {'icon': Icons.inventory_2, 'title': 'Produits', 'color': AppColors.lightAccentSecondary},
      {'icon': Icons.shopping_cart, 'title': 'Ventes', 'color': AppColors.lightStatusSuccess},
      {'icon': Icons.receipt_long, 'title': 'Factures', 'color': AppColors.lightStatusWarning},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context,
              action['icon'] as IconData,
              action['title'] as String,
              action['color'] as Color,
              isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Implement navigation
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context, AppProvider appProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du système',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                context,
                'Connexion',
                appProvider.isOnline ? 'En ligne' : 'Hors ligne',
                appProvider.isOnline ? AppColors.lightStatusSuccess : AppColors.lightStatusError,
                appProvider.isOnline ? Icons.wifi : Icons.wifi_off,
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusCard(
                context,
                'Synchronisation',
                appProvider.isSyncing ? 'En cours' : 'À jour',
                appProvider.isSyncing ? AppColors.lightStatusWarning : AppColors.lightStatusSuccess,
                appProvider.isSyncing ? Icons.sync : Icons.check_circle,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String status, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Center(
      child: Text(
        'Version 1.0.0 • Développé avec ❤️',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}