// screens/home_screen.dart
import 'package:cbook/models/business_book.dart';
import 'package:cbook/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/auth_provider.dart';
import 'package:cbook/providers/business_book_provider.dart';
import 'package:cbook/screens/dashboard_screen.dart';
import 'package:cbook/screens/transactions_screen.dart';
import 'package:cbook/screens/debtors_screen.dart';
import 'package:cbook/screens/creditors_screen.dart';
import 'package:cbook/screens/reports_screen.dart';
import 'package:cbook/screens/settings_screen.dart';
import 'package:cbook/screens/business_book_screen.dart';
import 'package:cbook/screens/team_management_screen.dart';
import 'package:cbook/screens/book_settings_screen.dart';
import 'package:cbook/screens/business_stats_screen.dart';
import 'package:cbook/screens/user_profile_screen.dart';
import 'package:cbook/screens/guide_screen.dart'; // Add guide screen import

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    DebtorsScreen(),
    ReportsScreen(),
  ];

  final List<String> _appBarTitles = [
    'Dashboard',
    'Transactions',
    'Debtors',
    'Reports'
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookProvider = Provider.of<BusinessBookProvider>(context);
    final currentBook = bookProvider.currentBook;
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_appBarTitles[_currentIndex]),
            if (currentBook != null)
              Text(
                currentBook.name,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          // Business Book Quick Access
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.business),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusinessBookScreen()),
                );
              },
              tooltip: 'Business Book',
            ),
          
          // Creditors Access
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.account_balance_wallet),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditorsScreen()),
                );
              },
              tooltip: 'Creditors',
            ),
          
          // Quick Actions Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuSelection(value, context),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'business_book',
                child: ListTile(
                  leading: Icon(Icons.business, color: Colors.green),
                  title: Text('Business Book'),
                ),
              ),
              PopupMenuItem(
                value: 'team_management',
                child: ListTile(
                  leading: Icon(Icons.people, color: Colors.blue),
                  title: Text('Team Management'),
                ),
              ),
              PopupMenuItem(
                value: 'book_settings',
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.orange),
                  title: Text('Book Settings'),
                ),
              ),
              PopupMenuItem(
                value: 'business_stats',
                child: ListTile(
                  leading: Icon(Icons.analytics, color: Colors.purple),
                  title: Text('Business Stats'),
                ),
              ),
              PopupMenuItem(
                value: 'user_profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.teal),
                  title: Text('My Profile'),
                ),
              ),
              PopupMenuItem(
                value: 'guide', // Add guide to popup menu
                child: ListTile(
                  leading: Icon(Icons.help, color: Colors.blue),
                  title: Text('How to Use'),
                ),
              ),
              PopupMenuItem(
                value: 'app_settings',
                child: ListTile(
                  leading: Icon(Icons.settings_applications, color: Colors.grey),
                  title: Text('App Settings'),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, currentBook, currentUser, authProvider, bookProvider),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange[700],
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Debtors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 1 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add-transaction');
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.orange,
          )
        : null,
    );
  }

  Widget _buildDrawer(BuildContext context, BusinessBook? currentBook, User? currentUser, 
                      AuthProvider authProvider, BusinessBookProvider bookProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.account_balance_wallet, size: 30, color: Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                currentBook?.name ?? 'CBook NG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                currentUser?.businessName ?? 'Business',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Business Section
        ListTile(
          leading: Icon(Icons.business, color: Colors.green),
          title: Text('Business Book'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessBookScreen()));
          },
        ),

        // Team Management
        ListTile(
          leading: Icon(Icons.people, color: Colors.blue),
          title: Text('Team Management'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => TeamManagementScreen()));
          },
        ),

        // Book Settings
        ListTile(
          leading: Icon(Icons.settings, color: Colors.orange),
          title: Text('Book Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => BookSettingsScreen()));
          },
        ),

        // Business Stats
        ListTile(
          leading: Icon(Icons.analytics, color: Colors.purple),
          title: Text('Business Statistics'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessStatsScreen()));
          },
        ),

        Divider(),

        // User Profile
        ListTile(
          leading: Icon(Icons.person, color: Colors.teal),
          title: Text('My Profile'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen()));
          },
        ),

        // App Settings
        ListTile(
          leading: Icon(Icons.settings_applications, color: Colors.grey),
          title: Text('App Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
          },
        ),

        // Guide Screen - ADDED HERE
        ListTile(
          leading: Icon(Icons.help, color: Colors.blue),
          title: Text('How to Use'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => GuideScreen()));
          },
        ),

        Divider(),

        // Quick Actions
        ListTile(
          leading: Icon(Icons.add, color: Colors.orange),
          title: Text('New Transaction'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/add-transaction');
          },
        ),

        ListTile(
          leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
          title: Text('Creditors'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => CreditorsScreen()));
          },
        ),

        Divider(),

        // Logout
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text('Logout'),
          onTap: () async {
            Navigator.pop(context);
            await authProvider.logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}

  void _handleMenuSelection(String value, BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    switch (value) {
      case 'business_book':
        Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessBookScreen()));
        break;
      case 'team_management':
        Navigator.push(context, MaterialPageRoute(builder: (_) => TeamManagementScreen()));
        break;
      case 'book_settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookSettingsScreen()));
        break;
      case 'business_stats':
        Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessStatsScreen()));
        break;
      case 'user_profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen()));
        break;
      case 'guide': // Handle guide selection
        Navigator.push(context, MaterialPageRoute(builder: (_) => GuideScreen()));
        break;
      case 'app_settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
        break;
      case 'logout':
        await authProvider.logout();
        Navigator.pushReplacementNamed(context, '/login');
        break;
    }
  }

  // Override to handle back button press
  Future<bool> _onWillPop() async {
    // If not on dashboard, go to dashboard
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }
    // If on dashboard, show exit confirmation
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App?'),
        content: Text('Are you sure you want to exit CBook?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    super.dispose();
  }
}