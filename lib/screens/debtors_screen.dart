// screens/debtors_screen.dart
import 'package:cbook/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:cbook/utils/nigerian_localization.dart';
import 'package:intl/intl.dart';

class DebtorsScreen extends StatefulWidget {
  @override
  _DebtorsScreenState createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'balance'; // 'balance', 'name', 'date'
  bool _sortAscending = false;

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
    List<Contact> debtors = _filterAndSortDebtors(provider.debtors);

    final totalDebts = debtors.fold(0.0, (sum, debtor) => sum + debtor.balance);

    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search debtors...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Total Summary
          if (debtors.isNotEmpty)
            Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Outstanding:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '₦${NumberFormat('#,##0.00').format(totalDebts)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Debtors List
          Expanded(
            child: debtors.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: debtors.length,
                    itemBuilder: (context, index) {
                      final debtor = debtors[index];
                      return _buildDebtorCard(debtor, context, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Contact> _filterAndSortDebtors(List<Contact> debtors) {
    // Filter by search query
    var filtered = debtors.where((debtor) =>
        debtor.name.toLowerCase().contains(_searchQuery) ||
        (debtor.formattedBalance.toLowerCase().contains(_searchQuery))).toList();

    // Sort the list
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        case 'date':
          // For date sorting, use last transaction date or created date
          final aDate = a.lastTransactionDate ?? a.createdAt;
          final bDate = b.lastTransactionDate ?? b.createdAt;
          return _sortAscending
              ? aDate.compareTo(bDate)
              : bDate.compareTo(aDate);
        case 'balance':
        default:
          return _sortAscending
              ? a.balance.compareTo(b.balance)
              : b.balance.compareTo(a.balance);
      }
    });

    return filtered;
  }

  Widget _buildDebtorCard(Contact debtor, BuildContext context, TransactionProvider provider) {
    final debtorTransactions = provider.getTransactionsForContact(debtor.name);
    final lastTransaction = debtorTransactions.isNotEmpty ? debtorTransactions.first : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          foregroundColor: Colors.green[800],
          child: Text(
            debtor.initial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          debtor.displayName,
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
              'Balance: ${debtor.formattedBalanceWithCommas}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            if (debtor.phoneNumber != null)
              Text(
                'Phone: ${debtor.formattedPhoneNumber ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              ),
            if (lastTransaction != null)
              Text(
                'Last transaction: ${DateFormat('MMM dd').format(lastTransaction.date)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (debtor.isOverdue)
              Text(
                'Overdue: ${debtor.overdueStatus}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.payment, color: Colors.green),
              onPressed: () {
                _showReceivePaymentDialog(context, debtor, provider);
              },
              tooltip: 'Receive Payment',
            ),
            if (debtor.isOverdue)
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 16,
              ),
          ],
        ),
        onTap: () {
          _showDebtorDetails(debtor, context, provider);
        },
        onLongPress: () {
          _showDebtorOptions(debtor, context, provider);
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
            Icons.people,
            size: 64,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No debtors found',
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
                : 'Customers who owe you money will appear here',
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
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showReceivePaymentDialog(BuildContext context, Contact debtor, TransactionProvider provider) {
    final amountController = TextEditingController(text: debtor.balance.toStringAsFixed(2));
    String selectedPaymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Receive Payment from ${debtor.name}'),
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
                        // Validate amount doesn't exceed debt
                        final amount = double.tryParse(value) ?? 0;
                        if (amount > debtor.balance) {
                          amountController.text = debtor.balance.toStringAsFixed(2);
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
                      'Remaining balance: ₦${(debtor.balance - (double.tryParse(amountController.text) ?? 0)).toStringAsFixed(2)}',
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
                    if (amount != null && amount > 0 && amount <= debtor.balance) {
                      try {
                        // Generate the correct contact ID format (same as used in TransactionProvider)
                        final contactId = 'income_${debtor.name.toLowerCase().replaceAll(' ', '_')}';
                        await provider.receivePayment(contactId, amount, selectedPaymentMethod);
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment of ₦${amount.toStringAsFixed(2)} received successfully!'),
                            backgroundColor: Colors.green,
                          )
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          )
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid amount between ₦1 and ₦${debtor.balance.toStringAsFixed(2)}'),
                          backgroundColor: Colors.orange,
                        )
                      );
                    }
                  },
                  child: Text('Receive Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
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

  void _showDebtorDetails(Contact debtor, BuildContext context, TransactionProvider provider) {
    final transactions = provider.getTransactionsForContact(debtor.name);
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debtor Details - ${debtor.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Current Balance', debtor.formattedBalanceWithCommas, Colors.green[700]),
              _buildDetailRow('Status', debtor.balanceStatus, debtor.balanceColor),
              if (debtor.isOverdue)
                _buildDetailRow('Overdue Status', debtor.overdueStatus, Colors.red[700]),
              _buildDetailRow('Total Transactions', transactions.length.toString()),
              _buildDetailRow('Total Amount', '₦${NumberFormat('#,##0.00').format(totalAmount)}'),
              if (debtor.phoneNumber != null)
                _buildDetailRow('Phone', debtor.formattedPhoneNumber ?? '', Colors.blue[700]),
              if (debtor.businessName != null)
                _buildDetailRow('Business', debtor.businessName!, Colors.purple[700]),
              _buildDetailRow('Customer Since', DateFormat('MMM yyyy').format(debtor.createdAt)),
              SizedBox(height: 16),
              Text('Transaction History:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...transactions.take(5).map((transaction) => ListTile(
                title: Text(transaction.description),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
                trailing: Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    color: transaction.isIncome ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )).toList(),
              if (transactions.length > 5)
                Text('... and ${transactions.length - 5} more transactions',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])),
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
              _showReceivePaymentDialog(context, debtor, provider);
            },
            child: Text('Receive Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
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
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebtorOptions(Contact debtor, BuildContext context, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.payment, color: Colors.green[700]),
            title: Text('Receive Payment'),
            onTap: () {
              Navigator.pop(context);
              _showReceivePaymentDialog(context, debtor, provider);
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.blue[700]),
            title: Text('View Full History'),
            onTap: () {
              Navigator.pop(context);
              _showFullTransactionHistory(debtor, context, provider);
            },
          ),
          if (debtor.phoneNumber != null)
            ListTile(
              leading: Icon(Icons.message, color: Colors.orange[700]),
              title: Text('Send Reminder'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.purple[700]),
            title: Text('Edit Details'),
            onTap: () {
              Navigator.pop(context);
              _editDebtorDetails(debtor, context, provider);
            },
          ),
          if (debtor.isOverdue)
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red[700]),
              title: Text('Mark as Resolved'),
              onTap: () {
                Navigator.pop(context);
                _markAsResolved(debtor, context, provider);
              },
            ),
        ],
      ),
    );
  }

  void _showFullTransactionHistory(Contact debtor, BuildContext context, TransactionProvider provider) {
    final transactions = provider.getTransactionsForContact(debtor.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Full History - ${debtor.name}'),
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
                    color: transaction.isIncome ? Colors.green[700] : Colors.red[700],
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


  void _editDebtorDetails(Contact debtor, BuildContext context, TransactionProvider provider) {
    // TODO: Implement debtor editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(''),
        backgroundColor: Colors.purple[700],
      ),
    );
  }

  void _markAsResolved(Contact debtor, BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Resolved?'),
        content: Text('This will set the balance to zero and mark this debt as resolved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mark as resolved'),
                  backgroundColor: Colors.green[700],
                ),
              );
            },
            child: Text('Mark Resolved', style: TextStyle(color: Colors.green[700])),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sort Debtors By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: Text('Balance (High to Low)'),
              value: 'balance',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value.toString();
                  _sortAscending = false;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('Balance (Low to High)'),
              value: 'balance_asc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = 'balance';
                  _sortAscending = true;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('Name (A to Z)'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value.toString();
                  _sortAscending = true;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('Name (Z to A)'),
              value: 'name_desc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = 'name';
                  _sortAscending = false;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('Most Recent'),
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value.toString();
                  _sortAscending = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}