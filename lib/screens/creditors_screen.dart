// screens/creditors_screen.dart
import 'package:cbook/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:cbook/utils/nigerian_localization.dart';
import 'package:intl/intl.dart';

class CreditorsScreen extends StatefulWidget {
  @override
  _CreditorsScreenState createState() => _CreditorsScreenState();
}

class _CreditorsScreenState extends State<CreditorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    List<Contact> creditors = _filterCreditors(provider.creditors);

    final totalCredits = creditors.fold(0.0, (sum, creditor) => sum + creditor.balance);

    return Scaffold(
      appBar: AppBar(
        title: Text('Creditors'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search creditors...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Total Summary
          if (creditors.isNotEmpty)
            Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Owed:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '₦${NumberFormat('#,##0.00').format(totalCredits)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Creditors List
          Expanded(
            child: creditors.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: creditors.length,
                    itemBuilder: (context, index) {
                      final creditor = creditors[index];
                      return _buildCreditorCard(creditor, context, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Contact> _filterCreditors(List<Contact> creditors) {
    return creditors.where((creditor) =>
        creditor.name.toLowerCase().contains(_searchQuery) ||
        creditor.formattedBalance.toLowerCase().contains(_searchQuery)).toList();
  }

  Widget _buildCreditorCard(Contact creditor, BuildContext context, TransactionProvider provider) {
    final creditorTransactions = provider.getTransactionsForContact(creditor.name);
    final lastTransaction = creditorTransactions.isNotEmpty ? creditorTransactions.first : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[100],
          foregroundColor: Colors.red[800],
          child: Text(
            creditor.initial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          creditor.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2),
            Text(
              'Balance: ${creditor.formattedBalanceWithCommas}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            if (creditor.phoneNumber != null)
              Text(
                'Phone: ${creditor.formattedPhoneNumber ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              ),
            if (lastTransaction != null)
              Text(
                'Last transaction: ${DateFormat('MMM dd').format(lastTransaction.date)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.payment, color: Colors.green),
              onPressed: () {
                _showPayCreditorDialog(context, creditor, provider);
              },
              tooltip: 'Make Payment',
            ),
            if (creditor.balance > 10000) // Show warning for large credits
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 16,
              ),
          ],
        ),
        onTap: () {
          _showCreditorDetails(creditor, context, provider);
        },
        onLongPress: () {
          _showCreditorOptions(creditor, context, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 64,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No creditors found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Suppliers you owe money will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          if (_searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showPayCreditorDialog(BuildContext context, Contact creditor, TransactionProvider provider) {
    final amountController = TextEditingController(text: creditor.balance.toStringAsFixed(2));
    String selectedPaymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pay ${creditor.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (₦)',
                        prefixText: '₦ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        // Validate amount doesn't exceed credit
                        final amount = double.tryParse(value) ?? 0;
                        if (amount > creditor.balance) {
                          amountController.text = creditor.balance.toStringAsFixed(2);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: ['cash', 'transfer', 'pos']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(NigerianLocalization.getPaymentMethodDisplay(method)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Remaining balance: ₦${(creditor.balance - (double.tryParse(amountController.text) ?? 0)).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0 && amount <= creditor.balance) {
                      try {
                        await provider.payCreditor(creditor.id, amount, selectedPaymentMethod);
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payment of ₦${amount.toStringAsFixed(2)} made successfully!'))
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'))
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid amount between ₦1 and ₦${creditor.balance.toStringAsFixed(2)}'))
                      );
                    }
                  },
                  child: Text('Make Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreditorDetails(Contact creditor, BuildContext context, TransactionProvider provider) {
    final transactions = provider.getTransactionsForContact(creditor.name);
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Creditor Details - ${creditor.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Current Balance', creditor.formattedBalanceWithCommas, Colors.red),
              _buildDetailRow('Total Transactions', transactions.length.toString()),
              _buildDetailRow('Total Amount', '₦${NumberFormat('#,##0.00').format(totalAmount)}'),
              if (creditor.phoneNumber != null)
                _buildDetailRow('Phone', creditor.formattedPhoneNumber ?? '', Colors.blue),
              if (creditor.businessName != null)
                _buildDetailRow('Business', creditor.businessName!, Colors.purple),
              SizedBox(height: 16),
              Text('Transaction History:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...transactions.take(5).map((transaction) => ListTile(
                title: Text(transaction.description),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
                trailing: Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    color: transaction.isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )).toList(),
              if (transactions.length > 5)
                Text('... and ${transactions.length - 5} more transactions',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPayCreditorDialog(context, creditor, provider);
            },
            child: Text('Make Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreditorOptions(Contact creditor, BuildContext context, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.payment, color: Colors.green),
            title: Text('Make Payment'),
            onTap: () {
              Navigator.pop(context);
              _showPayCreditorDialog(context, creditor, provider);
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.blue),
            title: Text('View Full History'),
            onTap: () {
              Navigator.pop(context);
              _showFullTransactionHistory(creditor, context, provider);
            },
          ),
          if (creditor.phoneNumber != null)
            ListTile(
              leading: Icon(Icons.phone, color: Colors.orange),
              title: Text('Contact Supplier'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.purple),
            title: Text('Edit Details'),
            onTap: () {
              Navigator.pop(context);
              _editCreditorDetails(creditor, context, provider);
            },
          ),
        ],
      ),
    );
  }

  void _showFullTransactionHistory(Contact creditor, BuildContext context, TransactionProvider provider) {
    final transactions = provider.getTransactionsForContact(creditor.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Full History - ${creditor.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                title: Text(transaction.description),
                subtitle: Text(DateFormat('MMM dd, yyyy - HH:mm').format(transaction.date)),
                trailing: Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    color: transaction.isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }


  void _editCreditorDetails(Contact creditor, BuildContext context, TransactionProvider provider) {
    // TODO: Implement creditor editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('')),
    );
  }
}