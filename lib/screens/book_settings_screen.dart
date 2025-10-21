import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/business_book_provider.dart';
import 'package:cbook/models/business_book.dart';
import 'package:cbook/providers/transaction_provider.dart'; // Add this import

class BookSettingsScreen extends StatefulWidget {
  @override
  _BookSettingsScreenState createState() => _BookSettingsScreenState();
}

class _BookSettingsScreenState extends State<BookSettingsScreen> {
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  String _selectedCurrency = 'NGN';
  String _fiscalYearStart = 'January';
  bool _enableVat = true;
  bool _autoBackup = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final provider = Provider.of<BusinessBookProvider>(context, listen: false);
    final book = provider.currentBook;
    
    if (book != null) {
      _businessNameController.text = book.name;
      _businessTypeController.text = book.businessType;
      _selectedCurrency = book.currency;
      _enableVat = book.settings.enableVat;
      _autoBackup = book.settings.autoBackup;
      _fiscalYearStart = book.settings.fiscalYearStart;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessBookProvider>(context);
    final book = provider.currentBook;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Book Settings')),
        body: Center(child: Text('No business book selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveSettings(context, provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            _buildSectionHeader('Basic Information'),
            _buildTextField(_businessNameController, 'Business Name'),
            _buildTextField(_businessTypeController, 'Business Type'),
            
            // Currency Settings
            _buildSectionHeader('Currency Settings'),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(labelText: 'Currency'),
              items: ['NGN', 'USD', 'EUR', 'GBP', 'GHS']
                  .map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCurrency = value!),
            ),
            
            // Tax Settings
            _buildSectionHeader('Tax Settings'),
            SwitchListTile(
              title: Text('Enable VAT'),
              subtitle: Text('Add 7.5% VAT to sales'),
              value: _enableVat,
              onChanged: (value) => setState(() => _enableVat = value),
            ),
            
            // Fiscal Year
            _buildSectionHeader('Fiscal Year'),
            DropdownButtonFormField<String>(
              value: _fiscalYearStart,
              decoration: InputDecoration(labelText: 'Fiscal Year Starts'),
              items: [
                'January', 'February', 'March', 'April', 'May', 'June',
                'July', 'August', 'September', 'October', 'November', 'December'
              ].map((month) => DropdownMenuItem(value: month, child: Text(month))).toList(),
              onChanged: (value) => setState(() => _fiscalYearStart = value!),
            ),
            
            // Backup Settings
            _buildSectionHeader('Backup & Sync'),
            SwitchListTile(
              title: Text('Auto Backup'),
              subtitle: Text('Automatically backup data to cloud'),
              value: _autoBackup,
              onChanged: (value) => setState(() => _autoBackup = value),
            ),
            
            // Danger Zone
            _buildSectionHeader('Danger Zone'),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danger Zone', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('These actions are irreversible', style: TextStyle(color: Colors.red[700])),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isDeleting ? null : () => _showDeleteConfirmation(context, provider),
                      child: _isDeleting 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Delete Business Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _saveSettings(context, provider),
              child: Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _saveSettings(BuildContext context, BusinessBookProvider provider) {
    final newSettings = BookSettings(
      enableVat: _enableVat,
      vatRate: 7.5,
      fiscalYearStart: _fiscalYearStart,
      autoBackup: _autoBackup,
      multiCurrency: _selectedCurrency != 'NGN',
    );

    provider.updateBookSettings(newSettings);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully')),
    );
  }

  void _showDeleteConfirmation(BuildContext context, BusinessBookProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Business Book?'),
        content: Text('This action cannot be undone. All transactions, contacts, and data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBusinessBook(context, provider);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBusinessBook(BuildContext context, BusinessBookProvider provider) async {
    final book = provider.currentBook;
    if (book == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Get the transaction provider to clear data
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Remove book data from transaction provider first
      await transactionProvider.removeBookData(book.id);
      
      // Delete the book from the business book provider
      await provider.deleteBook(book.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Business book deleted successfully')),
      );
      
      // Navigate back to books list or home screen
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete business book: $e')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }
}