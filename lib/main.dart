import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Core services
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';

// Presentation providers
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/cart_screen_provider.dart';
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

// Theme
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  
  final syncService = SyncService();
  await syncService.initialize();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    const NdieugBiApp(),
  );
}

class NdieugBiApp extends StatelessWidget {
  const NdieugBiApp({super.key});

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
