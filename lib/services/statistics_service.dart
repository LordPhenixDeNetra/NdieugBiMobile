import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../domain/models/product.dart';
import '../domain/entities/invoice.dart';
import '../data/models/invoice_model.dart';
import 'data_source_service.dart';

/// Modèle pour les statistiques rapides
class QuickStats {
  final int totalProducts;
  final int todaySales;
  final double monthlyRevenue;
  final double growthPercentage;

  const QuickStats({
    required this.totalProducts,
    required this.todaySales,
    required this.monthlyRevenue,
    required this.growthPercentage,
  });

  static const QuickStats empty = QuickStats(
    totalProducts: 0,
    todaySales: 0,
    monthlyRevenue: 0.0,
    growthPercentage: 0.0,
  );
}

/// Types d'activité récente
enum ActivityType {
  sale,
  stockUpdate,
  lowStock,
  newProduct,
  invoice,
}

/// Modèle pour une activité récente
class RecentActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.metadata,
  });

  /// Retourne le temps écoulé depuis l'activité
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return 'Il y a ${(difference.inDays / 7).floor()} semaine${(difference.inDays / 7).floor() > 1 ? 's' : ''}';
    }
  }

  /// Convertit depuis une Map
  factory RecentActivity.fromMap(Map<String, dynamic> map) {
    return RecentActivity(
      id: map['id'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.sale,
      ),
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }

  /// Convertit vers une Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Service de gestion des statistiques et activités récentes
class StatisticsService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final DataSourceService _dataSourceService;
  
  // Contrôleurs de flux pour les données
  final StreamController<QuickStats> _statisticsController = StreamController<QuickStats>.broadcast();
  final StreamController<List<RecentActivity>> _activitiesController = StreamController<List<RecentActivity>>.broadcast();
  
  // États internes
  QuickStats _currentStats = QuickStats.empty;
  List<RecentActivity> _recentActivities = [];
  bool _isInitialized = false;
  bool _isLoadingStats = false;
  bool _isLoadingActivities = false;
  String? _statsError;
  String? _activitiesError;

  StatisticsService({
    required DatabaseService databaseService,
    required DataSourceService dataSourceService,
  }) : _databaseService = databaseService,
       _dataSourceService = dataSourceService;

  // Getters pour les flux
  Stream<QuickStats> get statisticsStream => _statisticsController.stream;
  Stream<List<RecentActivity>> get activitiesStream => _activitiesController.stream;
  
  // Getters pour les données actuelles
  QuickStats get currentStats => _currentStats;
  List<RecentActivity> get recentActivities => _recentActivities;
  bool get isInitialized => _isInitialized;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingActivities => _isLoadingActivities;
  String? get statsError => _statsError;
  String? get activitiesError => _activitiesError;

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        _loadStatistics(),
        _loadRecentActivities(),
      ]);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du StatisticsService: $e');
    }
  }

  /// Rafraîchit toutes les données
  Future<void> refreshAll() async {
    await Future.wait([
      refreshStats(),
      refreshActivities(),
    ]);
  }

  /// Rafraîchit les statistiques
  Future<void> refreshStats() async {
    await _loadStatistics();
  }

  /// Rafraîchit les activités récentes
  Future<void> refreshActivities() async {
    await _loadRecentActivities();
  }

  /// Charge les statistiques
  Future<void> _loadStatistics() async {
    if (_isLoadingStats) return;

    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      final stats = await _calculateQuickStats();
      _currentStats = stats;
      _statisticsController.add(stats);
    } catch (e) {
      _statsError = 'Erreur lors du chargement des statistiques: $e';
      debugPrint(_statsError);
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Charge les activités récentes
  Future<void> _loadRecentActivities() async {
    if (_isLoadingActivities) return;

    _isLoadingActivities = true;
    _activitiesError = null;
    notifyListeners();

    try {
      final activities = await _generateRecentActivities();
      _recentActivities = activities;
      _activitiesController.add(activities);
    } catch (e) {
      _activitiesError = 'Erreur lors du chargement des activités: $e';
      debugPrint(_activitiesError);
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  /// Génère les activités récentes basées sur les données
  Future<List<RecentActivity>> _generateRecentActivities() async {
    final activities = <RecentActivity>[];
    
    try {
      // Récupérer les factures récentes
      final invoices = await _getInvoices();
      final recentInvoices = invoices
          .where((invoice) => DateTime.now().difference(invoice.createdAt).inDays <= 7)
          .take(10)
          .toList();
      
      for (final invoice in recentInvoices) {
        activities.add(RecentActivity(
          id: 'invoice_${invoice.id}',
          type: ActivityType.invoice,
          title: 'Facture #${invoice.invoiceNumber}',
          subtitle: '${invoice.total.toStringAsFixed(2)} €',
          timestamp: invoice.createdAt,
          metadata: {'invoiceId': invoice.id, 'total': invoice.total},
        ));
      }
      
      // Récupérer les produits en rupture de stock
      final products = await _getProducts();
      final lowStockProducts = products
          .where((product) => product.stock <= 10 && product.stock > 0)
          .take(5)
          .toList();
      
      for (final product in lowStockProducts) {
        activities.add(RecentActivity(
          id: 'lowstock_${product.id}',
          type: ActivityType.lowStock,
          title: 'Stock faible: ${product.name}',
          subtitle: '${product.stock} unités restantes',
          timestamp: DateTime.now().subtract(Duration(hours: product.stock)),
          metadata: {'productId': product.id, 'stock': product.stock},
        ));
      }
      
      // Trier par timestamp décroissant
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return activities.take(20).toList();
    } catch (e) {
      debugPrint('Erreur lors de la génération des activités: $e');
      return [];
    }
  }

  /// Calcule les statistiques de l'aperçu rapide
  Future<QuickStats> _calculateQuickStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    // Récupérer les produits
    final products = await _getProducts();
    final totalProducts = products.length;
    // Variables pour les statistiques de stock (peuvent être utilisées plus tard)
    // final lowStockProducts = products.where((p) => p.stock > 0 && p.stock <= 10).length;
    // final outOfStockProducts = products.where((p) => p.stock <= 0).length;

    // Récupérer les factures
    final allInvoices = await _getInvoices();
    
    // Ventes d'aujourd'hui
    final todayInvoices = allInvoices.where((invoice) {
      return invoice.createdAt.isAfter(today) && 
             invoice.createdAt.isBefore(today.add(const Duration(days: 1)));
    }).toList();
    final todaySales = todayInvoices.length;

    // Revenus de ce mois
    final thisMonthInvoices = allInvoices.where((invoice) {
      return invoice.createdAt.isAfter(thisMonth) && 
             invoice.createdAt.isBefore(nextMonth);
    }).toList();
    final monthlyRevenue = thisMonthInvoices.fold<double>(
      0.0, 
      (sum, invoice) => sum + invoice.total,
    );

    // Revenus du mois dernier pour calculer la croissance
    final lastMonthInvoices = allInvoices.where((invoice) {
      return invoice.createdAt.isAfter(lastMonth) && 
             invoice.createdAt.isBefore(thisMonth);
    }).toList();
    final lastMonthRevenue = lastMonthInvoices.fold<double>(
      0.0, 
      (sum, invoice) => sum + invoice.total,
    );

    // Calcul du pourcentage de croissance
    double growthPercentage = 0.0;
    if (lastMonthRevenue > 0) {
      growthPercentage = ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
    } else if (monthlyRevenue > 0) {
      growthPercentage = 100.0; // 100% de croissance si pas de revenus le mois dernier
    }

    return QuickStats(
      totalProducts: totalProducts,
      todaySales: todaySales,
      monthlyRevenue: monthlyRevenue,
      growthPercentage: growthPercentage,
    );
  }

  /// Récupère la liste des produits
  Future<List<Product>> _getProducts() async {
    try {
      return await _dataSourceService.getProducts();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  /// Récupère la liste des factures
  Future<List<Invoice>> _getInvoices() async {
    try {
      final invoicesData = await _databaseService.getAllInvoices();
      return invoicesData.map((data) {
        // Utiliser InvoiceModel.fromMap puis convertir en entité
        final invoiceModel = InvoiceModel.fromMap(data);
        return invoiceModel.toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des factures: $e');
      return [];
    }
  }

  /// Obtient les statistiques détaillées des produits
  Future<Map<String, dynamic>> getProductStatistics() async {
    final products = await _getProducts();
    
    return {
      'total': products.length,
      'inStock': products.where((p) => p.stock > 0).length,
      'lowStock': products.where((p) => p.stock > 0 && p.stock <= 10).length,
      'outOfStock': products.where((p) => p.stock <= 0).length,
      'averagePrice': products.isEmpty ? 0.0 : 
        products.fold<double>(0.0, (sum, p) => sum + p.price) / products.length,
      'totalValue': products.fold<double>(0.0, (sum, p) => sum + (p.price * p.stock)),
    };
  }

  /// Obtient les statistiques des ventes
  Future<Map<String, dynamic>> getSalesStatistics() async {
    final invoices = await _getInvoices();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);

    final todayInvoices = invoices.where((i) => 
      i.createdAt.isAfter(today) && 
      i.createdAt.isBefore(today.add(const Duration(days: 1)))
    ).toList();

    final weekInvoices = invoices.where((i) => 
      i.createdAt.isAfter(thisWeek)
    ).toList();

    final monthInvoices = invoices.where((i) => 
      i.createdAt.isAfter(thisMonth)
    ).toList();

    return {
      'today': {
        'count': todayInvoices.length,
        'total': todayInvoices.fold<double>(0.0, (sum, i) => sum + i.total),
      },
      'thisWeek': {
        'count': weekInvoices.length,
        'total': weekInvoices.fold<double>(0.0, (sum, i) => sum + i.total),
      },
      'thisMonth': {
        'count': monthInvoices.length,
        'total': monthInvoices.fold<double>(0.0, (sum, i) => sum + i.total),
      },
      'average': invoices.isEmpty ? 0.0 :
        invoices.fold<double>(0.0, (sum, i) => sum + i.total) / invoices.length,
    };
  }

  /// Force la mise à jour des statistiques
  void forceRefresh() {
    refreshStats();
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _statisticsController.close();
    _activitiesController.close();
    super.dispose();
  }
}