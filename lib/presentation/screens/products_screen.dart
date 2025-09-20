import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/ui_provider.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/add_product_form.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize screen only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _initializeScreen();
        _isInitialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, ConnectivityProvider, UiProvider>(
      builder: (context, productProvider, connectivityProvider, uiProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            controller: _getScrollController(context, uiProvider),
            slivers: [
              _buildAppBar(context, productProvider, uiProvider),
              if (!connectivityProvider.isOnline)
                SliverToBoxAdapter(
                  child: ConnectivityBanner(
                    status: connectivityProvider.status,
                    onRetry: () => connectivityProvider.checkConnectivity(),
                  ),
                ),
              _buildSearchAndFilters(context, productProvider, uiProvider),
              _buildProductGrid(context, productProvider, uiProvider),
            ],
          ),
          floatingActionButton: AnimatedScale(
            scale: uiProvider.showFab ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau Produit'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }

  void _initializeScreen() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final uiProvider = Provider.of<UiProvider>(context, listen: false);
    
    // Load products if not already loaded
    if (productProvider.products.isEmpty && !productProvider.isLoading) {
      productProvider.loadProducts();
    }
    
    // Initialize scroll controller if not exists
    if (uiProvider.getScrollController('products') == null) {
      final scrollController = ScrollController();
      scrollController.addListener(() {
        uiProvider.handleScroll('products', scrollController.offset);
      });
      uiProvider.registerScrollController('products', scrollController);
    }
  }

  ScrollController _getScrollController(BuildContext context, UiProvider uiProvider) {
    return uiProvider.getScrollController('products') ?? ScrollController();
  }

  Widget _buildAppBar(BuildContext context, ProductProvider productProvider, UiProvider uiProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return FadeTransition(
              opacity: uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0),
              child: const Text(
                'Produits',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: productProvider.isLoading 
              ? null 
              : () => productProvider.refresh(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: (value) => _handleSort(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'name_asc',
              child: Text('Nom (A-Z)'),
            ),
            const PopupMenuItem(
              value: 'name_desc',
              child: Text('Nom (Z-A)'),
            ),
            const PopupMenuItem(
              value: 'price_asc',
              child: Text('Prix (croissant)'),
            ),
            const PopupMenuItem(
              value: 'price_desc',
              child: Text('Prix (décroissant)'),
            ),
            const PopupMenuItem(
              value: 'stock_asc',
              child: Text('Stock (croissant)'),
            ),
            const PopupMenuItem(
              value: 'stock_desc',
              child: Text('Stock (décroissant)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ProductProvider productProvider, UiProvider uiProvider) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0)),
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0)),
            child: FadeTransition(
              opacity: uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SearchBarWidget(
                      hintText: 'Rechercher des produits...',
                      onChanged: (query) => productProvider.searchProducts(query),
                      onClear: () => productProvider.searchProducts(''),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryFilters(context, productProvider),
                    const SizedBox(height: 8),
                    _buildStatsRow(context, productProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, ProductProvider productProvider) {
    final categories = productProvider.categories;
    
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChipWidget(
                label: 'Tous',
                isSelected: productProvider.selectedCategory.isEmpty,
                onSelected: (_) => productProvider.filterByCategory(''),
              ),
            );
          }
          
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChipWidget(
              label: category,
              isSelected: productProvider.selectedCategory == category,
              onSelected: (_) => productProvider.filterByCategory(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ProductProvider productProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          context,
          'Total',
          productProvider.totalProducts.toString(),
          Icons.inventory,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Stock Bas',
          productProvider.lowStockProducts.length.toString(),
          Icons.warning,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Rupture',
          productProvider.outOfStockProducts.length.toString(),
          Icons.error,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, ProductProvider productProvider, UiProvider uiProvider) {
    if (productProvider.isLoading) {
      return const SliverFillRemaining(
        child: LoadingWidget(message: 'Chargement des produits...'),
      );
    }

    if (productProvider.error != null) {
      return SliverFillRemaining(
        child: CustomErrorWidget(
          title: 'Erreur',
          message: productProvider.error!,
          onRetry: () => productProvider.refresh(),
        ),
      );
    }

    if (productProvider.products.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: 'Aucun produit trouvé',
          subtitle: productProvider.searchQuery.isNotEmpty
              ? 'Aucun produit ne correspond à votre recherche'
              : 'Commencez par ajouter des produits',
          actionText: 'Ajouter un produit',
          onAction: () => _showAddProductDialog(context),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = productProvider.products[index];
            return AnimatedBuilder(
              animation: uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return FadeTransition(
                  opacity: uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(uiProvider.getAnimationController('products') ?? const AlwaysStoppedAnimation(1.0)),
                    child: ProductCard(
                      product: product,
                      onTap: () => _showProductDetails(context, product),
                      onEdit: () => _showEditProductDialog(context, product),
                      onDelete: () => _showDeleteConfirmation(context, product),
                    ),
                  ),
                );
              },
            );
          },
          childCount: productProvider.products.length,
        ),
      ),
    );
  }

  void _handleSort(BuildContext context, String sortValue) {
    final parts = sortValue.split('_');
    final sortBy = parts[0];
    final ascending = parts[1] == 'asc';
    
    context.read<ProductProvider>().sortProducts(sortBy, ascending: ascending);
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddProductForm(),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    // TODO: Navigate to product details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails de ${product.name}')),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    // TODO: Implement edit product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modifier ${product.name}')),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ProductProvider>().deleteProduct(product.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}