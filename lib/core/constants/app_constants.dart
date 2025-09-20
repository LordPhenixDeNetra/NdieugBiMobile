class AppConstants {
  // App Info
  static const String appName = 'NdieugBi';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'ndieug_bi.db';
  static const int databaseVersion = 1;
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8080/api';
  static const String baseUrl = 'http://localhost:8080/api'; // Backward compatibility
  static const String connectivityTestUrl = 'https://www.google.com';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int connectivityTimeout = 10; // Timeout in seconds for connectivity tests
  static const int connectivityCheckInterval = 30; // Interval in seconds for periodic connectivity checks
  
  // Sync Configuration
  static const Duration autoSyncInterval = Duration(minutes: 15);
  static const Duration syncTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String offlineModeKey = 'offline_mode';
  static const String lastSyncKey = 'last_sync';
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String firstLaunchKey = 'first_launch';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Paths
  static const String invoicesPath = 'invoices';
  static const String backupsPath = 'backups';
  static const String exportsPath = 'exports';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxProductNameLength = 100;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // Currency
  static const String defaultCurrency = 'XOF';
  static const String currencySymbol = 'CFA';
  
  // Barcode
  static const Duration scanDelay = Duration(milliseconds: 500);
  static const int maxBarcodeLength = 50;
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Error Messages
  static const String networkErrorMessage = 'Erreur de connexion réseau';
  static const String serverErrorMessage = 'Erreur du serveur';
  static const String unknownErrorMessage = 'Une erreur inconnue s\'est produite';
  
  // Success Messages
  static const String saveSuccessMessage = 'Enregistré avec succès';
  static const String deleteSuccessMessage = 'Supprimé avec succès';
  static const String updateSuccessMessage = 'Mis à jour avec succès';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String productsEndpoint = '/products';
  static const String cartsEndpoint = '/carts';
  static const String syncEndpoint = '/sync';
  
  // Product Categories
  static const List<String> defaultCategories = [
    'Électronique',
    'Vêtements',
    'Alimentation',
    'Maison',
    'Sport',
    'Beauté',
    'Livres',
    'Jouets',
    'Automobile',
    'Autres',
  ];
  
  // Tax Rates
  static const double defaultTaxRate = 0.18; // 18% TVA
  static const double zeroTaxRate = 0.0;
  
  // Discount Limits
  static const double maxDiscountPercentage = 100.0;
  static const double minDiscountPercentage = 0.0;
  
  // Stock Limits
  static const int lowStockThreshold = 10;
  static const int outOfStockThreshold = 0;
  
  // Search Configuration
  static const int minSearchLength = 2;
  static const Duration searchDebounce = Duration(milliseconds: 300);
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
}