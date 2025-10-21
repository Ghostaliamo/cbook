// screens/business_book_screen.dart
import 'package:cbook/models/business_book.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/business_book_provider.dart';
import 'package:cbook/providers/auth_provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:cbook/screens/team_management_screen.dart';
import 'package:cbook/screens/book_settings_screen.dart';
import 'package:cbook/screens/business_stats_screen.dart';
import 'package:cbook/screens/user_profile_screen.dart';
import 'package:cbook/screens/transactions_screen.dart';
import 'package:intl/intl.dart';

class BusinessBookScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BusinessBookProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currentBook = bookProvider.currentBook;

    if (currentBook == null) {
      return _buildNoBookSelected(context, bookProvider, authProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentBook.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz, size: 22),
            onPressed: () => _showBookSwitchDialog(context, bookProvider, authProvider),
            tooltip: 'Switch Book',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookHeader(currentBook),
            SizedBox(height: 28),
            _buildFinancialOverview(transactionProvider),
            SizedBox(height: 28),
            _buildQuickActions(context),
            SizedBox(height: 28),
            _buildRecentTransactions(transactionProvider, context),
            SizedBox(height: 28),
            _buildTeamMembersPreview(currentBook, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBookSelected(BuildContext context, BusinessBookProvider bookProvider, AuthProvider authProvider) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Books', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.book, size: 60, color: Colors.orange[700]),
            ),
            SizedBox(height: 24),
            
            // Title
            Text(
              'No Business Book Selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Create or select a business book to manage your finances',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            
            // Status Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        authProvider.isLoggedIn ? Icons.check_circle : Icons.error_outline,
                        size: 18,
                        color: authProvider.isLoggedIn ? Colors.green : Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        authProvider.isLoggedIn ? 'Logged In' : 'Not Logged In',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: authProvider.isLoggedIn ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (authProvider.currentUser != null) ...[
                    SizedBox(height: 8),
                    Text(
                      authProvider.currentUser!.email,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Action Buttons
            Column(
              children: [
                if (authProvider.isLoggedIn) ...[
                  _buildElevatedButton(
                    onPressed: () => _showCreateBookDialog(context, bookProvider, authProvider),
                    text: 'Create New Business Book',
                    icon: Icons.add,
                  ),
                  SizedBox(height: 12),
                ] else ...[
                  _buildElevatedButton(
                    onPressed: () => _showLoginRequiredDialog(context),
                    text: 'Login to Create Book',
                    icon: Icons.login,
                    backgroundColor: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  _buildOutlinedButton(
                    onPressed: () async {
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.register(
                          'test@example.com',
                          'password123',
                          'Test Business',
                          phoneNumber: '+2348123456789',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Test account created!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    text: 'Create Test Account',
                    icon: Icons.person_add,
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Go to Login Page',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                
                if (bookProvider.allBooks.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Text(
                    'Existing Books',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildOutlinedButton(
                    onPressed: () => _showBookSwitchDialog(context, bookProvider, authProvider),
                    text: 'Select Existing Book',
                    icon: Icons.folder_open,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookHeader(BusinessBook book) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business, color: Colors.orange[700], size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      book.businessType,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(height: 1),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(Icons.currency_exchange, 'Currency', book.currency),
              _buildInfoItem(Icons.calendar_today, 'Created', 
                  '${book.createdAt.day}/${book.createdAt.month}/${book.createdAt.year}'),
              _buildInfoItem(Icons.people, 'Team', '${book.teamMembers.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(TransactionProvider provider) {
    final monthlySummary = provider.monthlySummary;
    final financialHealth = provider.financialHealth;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('₦${monthlySummary['income']?.toStringAsFixed(0) ?? '0'}', 'Income', Colors.green),
              _buildStatItem('₦${monthlySummary['expense']?.toStringAsFixed(0) ?? '0'}', 'Expenses', Colors.orange),
              _buildStatItem('₦${(monthlySummary['income']! - monthlySummary['expense']!).toStringAsFixed(0)}', 'Profit', 
                  (monthlySummary['income']! - monthlySummary['expense']!) > 0 ? Colors.green : Colors.red),
            ],
          ),
          SizedBox(height: 16),
          Divider(height: 1),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profit Margin:', style: TextStyle(fontSize: 13)),
              Text(
                '${financialHealth['profitMargin']?.toStringAsFixed(1) ?? '0.0'}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (financialHealth['profitMargin'] ?? 0) > 10 ? Colors.green : 
                         (financialHealth['profitMargin'] ?? 0) > 5 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VAT Collected:', style: TextStyle(fontSize: 13)),
              Text(
                '₦${monthlySummary['vat']?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionChip(
              icon: Icons.people,
              label: 'Team',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamManagementScreen())),
            ),
            _buildActionChip(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookSettingsScreen())),
            ),
            _buildActionChip(
              icon: Icons.bar_chart,
              label: 'Stats',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessStatsScreen())),
            ),
            _buildActionChip(
              icon: Icons.person,
              label: 'Profile',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen())),
            ),
            _buildActionChip(
              icon: Icons.receipt,
              label: 'Transactions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(TransactionProvider provider, BuildContext context) {
    final recentTransactions = provider.recentTransactions.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${recentTransactions.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[800]),
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsScreen())),
              child: Text('View All', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: recentTransactions.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No recent transactions',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: recentTransactions.map((transaction) => ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: transaction.isIncome ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: transaction.isIncome ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    title: Text(
                      transaction.description,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, hh:mm a').format(transaction.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      transaction.formattedAmount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: transaction.isIncome ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTeamMembersPreview(BusinessBook book, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Team Members',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${book.teamMembers.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[800]),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ...book.teamMembers.take(3).map((member) => ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.person, size: 16, color: Colors.orange[700]),
                ),
                title: Text(
                  '${member.userId.substring(0, 6)}...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  member.role,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                visualDensity: VisualDensity.compact,
              )).toList(),
              if (book.teamMembers.length > 3)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamManagementScreen())),
                  child: Text(
                    'View all ${book.teamMembers.length} members',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.orange[700]),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    Color backgroundColor = Colors.orange,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildOutlinedButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange[700],
        side: BorderSide(color: Colors.orange[700]!),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context, BusinessBookProvider bookProvider, AuthProvider authProvider) {
    final _nameController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    final List<String> businessTypes = [
      'Retail', 'Wholesale', 'Service', 'Manufacturing', 'Restaurant',
      'E-commerce', 'Construction', 'Transportation', '', 'Education',
      'Agriculture', 'Technology', 'Real Estate', 'Entertainment', 'Other'
    ];

    String? selectedBusinessType;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Business Book',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Logged in as: ${authProvider.currentUser?.email ?? "Unknown"}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a business name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedBusinessType,
                      decoration: InputDecoration(
                        labelText: 'Business Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: businessTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedBusinessType = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a business type';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final userId = authProvider.currentUser?.id;
                        if (userId != null) {
                          try {
                            await bookProvider.createBusinessBook(
                              _nameController.text,
                              selectedBusinessType!,
                              userId,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Business book created successfully!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error creating business book: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('You need to be logged in to create a business book.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showBookSwitchDialog(BuildContext context, BusinessBookProvider provider, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Business Books',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              // Add Create Book button at the top
              if (authProvider.isLoggedIn)
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      _showCreateBookDialog(context, provider, authProvider);
                    },
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Create New Book'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              // Books list
              Expanded(
                child: provider.allBooks.isEmpty
                    ? Center(
                        child: Text(
                          'No business books available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: provider.allBooks.length,
                        itemBuilder: (context, index) {
                          final book = provider.allBooks[index];
                          return ListTile(
                            leading: Icon(Icons.business, color: Colors.orange[700]),
                            title: Text(book.name, style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(book.businessType),
                            trailing: provider.currentBook?.id == book.id
                                ? Icon(Icons.check, color: Colors.orange, size: 20)
                                : null,
                            onTap: () {
                              provider.switchBook(book.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}