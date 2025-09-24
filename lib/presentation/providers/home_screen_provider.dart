import 'package:flutter/material.dart';
import '../../services/statistics_service.dart';
import '../../services/data_source_service.dart';
import '../../services/database_service.dart';

class HomeScreenProvider extends ChangeNotifier {
  late final StatisticsService _statisticsService;
  
  bool _isInitialized = false;
  bool _isRefreshing = false;

  HomeScreenProvider() {
    // Initialiser le StatisticsService avec les dépendances nécessaires
    _statisticsService = StatisticsService(
      databaseService: DatabaseService(),
      dataSourceService: DataSourceService(),
    );
  }

  // Getters pour les statistiques
  bool get isInitialized => _isInitialized;
  bool get isRefreshing => _isRefreshing;
  QuickStats get quickStats => _statisticsService.currentStats;
  bool get isLoadingStats => _statisticsService.isLoadingStats;
  String? get statsError => _statisticsService.statsError;

  // Getters pour les activités récentes
  List<RecentActivity> get recentActivities => _statisticsService.recentActivities;
  bool get isLoadingActivities => _statisticsService.isLoadingActivities;
  String? get activitiesError => _statisticsService.activitiesError;

  /// Initialise le provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _statisticsService.initialize();
      _isInitialized = true;
      
      // Écouter les changements du service de statistiques
      _statisticsService.addListener(_onStatsChanged);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du HomeScreenProvider: $e');
    }
  }

  /// Callback appelé quand les statistiques changent
  void _onStatsChanged() {
    notifyListeners();
  }

  /// Rafraîchit toutes les données
  Future<void> refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      await _statisticsService.refreshAll();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Rafraîchit uniquement les statistiques
  Future<void> refreshStats() async {
    await _statisticsService.refreshStats();
  }

  /// Rafraîchit uniquement les activités récentes
  Future<void> refreshActivities() async {
    await _statisticsService.refreshActivities();
  }

  // Navigation methods
  void navigateToSales(BuildContext context) {
    Navigator.of(context).pushNamed('/cashier');
  }

  void navigateToInventory(BuildContext context) {
    // Navigate to products screen (inventory)
    Navigator.of(context).pushNamed('/products');
  }

  void navigateToInvoices(BuildContext context) {
    Navigator.of(context).pushNamed('/invoices');
  }

  void navigateToReports(BuildContext context) {
    // TODO: Navigate to reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les rapports')),
    );
  }

  void navigateToActivity(BuildContext context) {
    // TODO: Navigate to activity screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers l\'activité')),
    );
  }

  /// Navigue vers les détails d'une activité spécifique
  void navigateToActivityDetail(BuildContext context, RecentActivity activity) {
    switch (activity.type) {
      case ActivityType.invoice:
        // Naviguer vers les détails de la facture
        final invoiceId = activity.metadata?['invoiceId'];
        if (invoiceId != null) {
          Navigator.of(context).pushNamed('/invoice-detail', arguments: invoiceId);
        }
        break;
      case ActivityType.lowStock:
        // Naviguer vers les détails du produit
        final productId = activity.metadata?['productId'];
        if (productId != null) {
          Navigator.of(context).pushNamed('/product-detail', arguments: productId);
        }
        break;
      case ActivityType.sale:
      case ActivityType.stockUpdate:
      case ActivityType.newProduct:
        // Actions par défaut pour les autres types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Détails de l\'activité: ${activity.title}')),
        );
        break;
    }
  }

  @override
  void dispose() {
    _statisticsService.removeListener(_onStatsChanged);
    _statisticsService.dispose();
    super.dispose();
  }
}