import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cbook/providers/auth_provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:cbook/providers/business_book_provider.dart';
import 'package:cbook/screens/onboarding_screen.dart';
import 'package:cbook/screens/login_screen.dart';
import 'package:cbook/screens/register_screen.dart';
import 'package:cbook/screens/home_screen.dart';
import 'package:cbook/screens/dashboard_screen.dart';
import 'package:cbook/screens/transactions_screen.dart';
import 'package:cbook/screens/debtors_screen.dart';
import 'package:cbook/screens/creditors_screen.dart';
import 'package:cbook/screens/reports_screen.dart';
import 'package:cbook/screens/add_transaction_screen.dart';
import 'package:cbook/screens/settings_screen.dart';
import 'package:cbook/screens/business_book_screen.dart';
import 'package:cbook/screens/guide_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

// Import Firebase with prefix to resolve naming conflict
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'firebase_options.dart'; // Import your Firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (skip on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  try {
    await _initializeApp();
    runApp(MyApp());
  } catch (e, stackTrace) {
    print('App initialization failed: $e');
    print('Stack trace: $stackTrace');
    
    // Fallback UI if initialization fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 10),
                if (kIsWeb)
                  Text(
                    'If this persists, try clearing your browser cache.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  child: Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

Future<void> _initializeApp() async {
  // Initialize Firebase with your actual configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase - the app will work with in-memory storage
  }
  
  print('Using in-memory storage');
  
  // Initialize date formatting for Nigerian locale
  try {
    await initializeDateFormatting('en_NG', null);
    print('Date formatting initialized successfully');
  } catch (e) {
    print('Date formatting initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => BusinessBookProvider(),
          lazy: false,
        ),
        ChangeNotifierProxyProvider<BusinessBookProvider, TransactionProvider>(
          create: (context) => TransactionProvider(
            Provider.of<BusinessBookProvider>(context, listen: false),
          ),
          update: (context, businessBookProvider, transactionProvider) => 
            TransactionProvider(businessBookProvider),
        ),
      ],
      child: MaterialApp(
        title: 'CBook - The Cashbook',
        theme: _buildAppTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.light,
        home: AuthWrapper(),
        routes: _buildRoutes(),
        navigatorObservers: [AppNavigatorObserver()],
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus && 
                  currentFocus.focusedChild != null) {
                currentFocus.focusedChild?.unfocus();
              }
            },
            child: child,
          );
        },
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.orange,
      primaryColor: Colors.orange[700],
      primaryColorDark: Colors.orange[900],
      primaryColorLight: Colors.orange[100],
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orangeAccent,
        primary: Colors.orange[700]!,
        secondary: Colors.orangeAccent[700]!,
        background: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange[700],
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange[700],
          side: BorderSide(color: Colors.orange[700]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.orange,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orangeAccent,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
      ),
      useMaterial3: true,
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/onboarding': (context) => OnboardingScreen(),
      '/login': (context) => LoginScreen(),
      '/register': (context) => RegisterScreen(),
      '/home': (context) => HomeScreen(),
      '/dashboard': (context) => DashboardScreen(),
      '/transactions': (context) => TransactionsScreen(),
      '/debtors': (context) => DebtorsScreen(),
      '/creditors': (context) => CreditorsScreen(),
      '/reports': (context) => ReportsScreen(),
      '/add-transaction': (context) => AddTransactionScreen(),
      '/settings': (context) => SettingsScreen(),
      '/business-book': (context) => BusinessBookScreen(),
      '/guide': (context) => GuideScreen(),
    };
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // For web, add a small delay to ensure everything is loaded
      await Future.delayed(Duration(milliseconds: kIsWeb ? 1000 : 500));
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessBookProvider = Provider.of<BusinessBookProvider>(context, listen: false);
      
      // Check if user is logged in with Firebase
      try {
        final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
        print('Firebase user: ${firebaseUser?.email}');
        
        if (firebaseUser != null) {
          print('Syncing with Firebase user...');
          await authProvider.syncWithFirebaseUser(firebaseUser);
          await businessBookProvider.loadUserProfile(authProvider.currentUser!.id);
        }
      } catch (e) {
        print('Firebase auth check failed: $e');
        // Continue without Firebase
      }
      
    } catch (e) {
      print('AuthWrapper initialization error: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isInitializing) {
      return _buildSplashScreen();
    }

    if (authProvider.isLoggedIn) {
      // If logged in, check if a business book exists.
      final businessBookProvider = Provider.of<BusinessBookProvider>(context, listen: false);
      if (businessBookProvider.allBooks.isEmpty) {
        // Redirect to create a business book if none exist
        return BusinessBookScreen();
      }
      return HomeScreen();
    }

    return OnboardingScreen();
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.orange[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'CBook',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'The Cashbook',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            if (kIsWeb) SizedBox(height: 20),
            if (kIsWeb) Text(
              'Loading...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print('Navigated to: ${route.settings.name}');
  }
}

// Global key for navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void navigateTo(String routeName, {Object? arguments}) {
  navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
}

void showSnackBar(String message, {bool isError = false}) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}