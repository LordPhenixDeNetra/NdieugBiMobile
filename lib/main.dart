import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Core services
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'services/database_service.dart';
import 'services/data_source_service.dart';
import 'services/preferences_service.dart';

// Data repositories
import 'data/repositories/invoice_repository.dart';

// Presentation providers
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/cart_screen_provider.dart';
import 'presentation/providers/invoice_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/ui_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/cart_item_provider.dart';
import 'presentation/providers/theme_toggle_provider.dart';
import 'presentation/providers/search_bar_provider.dart';

// Screens
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/cashier_screen.dart';
import 'presentation/screens/invoices_list_screen.dart';
import 'presentation/screens/invoice_screen.dart';
import 'presentation/screens/menu_screen.dart';
import 'presentation/pages/debug_page.dart';

// Theme
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les services
  final connectivityService = ConnectivityService();
  final syncService = SyncService();
  final databaseService = DatabaseService();
  final dataSourceService = DataSourceService();
  final preferencesService = PreferencesService();

  await connectivityService.initialize();
  await syncService.initialize();
  await databaseService.initialize();
  await preferencesService.initialize();
  await dataSourceService.initialize();
  
  // Initialize repositories
  final invoiceRepository = InvoiceRepository(databaseService);
  
  // Set initial system UI overlay style (will be updated dynamically based on theme)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  runApp(
    NdieugBiApp(invoiceRepository: invoiceRepository),
  );
}

class NdieugBiApp extends StatelessWidget {
  final InvoiceRepository invoiceRepository;
  
  const NdieugBiApp({
    super.key,
    required this.invoiceRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => UiProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartScreenProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceProvider(invoiceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CartItemProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeToggleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchBarProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (themeProvider.isLoading) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          // Update system UI overlay style based on current theme
          final isDark = themeProvider.themeMode == ThemeMode.dark ||
              (themeProvider.themeMode == ThemeMode.system && 
               MediaQuery.of(context).platformBrightness == Brightness.dark);
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'NdieugBi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainNavigationScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/products': (context) => const ProductsScreen(),
              '/cart': (context) => const CartScreen(),
              '/cashier': (context) => const CashierScreen(),
              '/invoices': (context) => const InvoicesListScreen(),
              '/menu': (context) => const MenuScreen(),
              '/debug': (context) => const DebugPage(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/invoice') {
                final invoiceId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) {
                    return Consumer<InvoiceProvider>(
                      builder: (context, invoiceProvider, child) {
                        final invoice = invoiceProvider.getInvoiceFromList(invoiceId);
                        if (invoice != null) {
                          return InvoiceScreen(invoice: invoice);
                        } else {
                          // Load invoice if not in current list
                          invoiceProvider.loadInvoiceById(invoiceId);
                          return Scaffold(
                            appBar: AppBar(
                              title: const Text('Chargement...'),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            body: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final List<Widget> screens = [
          const HomeScreen(),
          const ProductsScreen(),
          const CartScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: (index) {
              navigationProvider.setCurrentIndex(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2),
                label: 'Produits',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Panier',
              ),
            ],
          ),
        );
      },
    );
  }
}
