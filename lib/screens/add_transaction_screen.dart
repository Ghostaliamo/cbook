// screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cbook/models/transaction.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _contactNameController = TextEditingController();
  
  String _transactionType = 'income';
  String _category = '';
  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _isCredit = false;
  bool _addVat = false;
  String? _receiptImagePath;
  
  final List<String> _incomeCategories = [
    'Product Sales',
    'Service Rendered',
    'Payment Received',
    'Other Income'
  ];
  
  final List<String> _expenseCategories = [
    'Raw Materials',
    'Transportation',
    'Utilities',
    'Rent',
    'Salaries',
    'Other Expenses'
  ];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['type'] != null) {
      _transactionType = args['type'];
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${_transactionType == 'income' ? 'Income' : 'Expense'}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Transaction Type Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Expense', style: TextStyle(color: _transactionType == 'expense' ? Colors.red : Colors.grey)),
                  Switch(
                    value: _transactionType == 'income',
                    onChanged: (value) {
                      setState(() {
                        _transactionType = value ? 'income' : 'expense';
                        _category = '';
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Text('Income', style: TextStyle(color: _transactionType == 'income' ? Colors.green : Colors.grey)),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (₦)',
                  prefixText: '₦ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _category.isEmpty ? null : _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                ),
                items: (_transactionType == 'income' ? _incomeCategories : _expenseCategories)
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Date Picker
              ListTile(
                title: Text('Date'),
                subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  
                  if (selectedDate != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    
                    if (selectedTime != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              
              SizedBox(height: 16),
              
              // Payment Method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                ),
                items: ['cash', 'transfer', 'pos']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _paymentMethod = newValue!;
                  });
                },
              ),
              
              SizedBox(height: 16),
              
              // Contact Name
              TextFormField(
                controller: _contactNameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name (Optional)',
                  hintText: 'e.g., Oga Emeka',
                ),
              ),
              
              SizedBox(height: 16),
              
              // Credit Transaction
              CheckboxListTile(
                title: Text('Credit Transaction'),
                subtitle: Text('Customer will pay later/You will pay later'),
                value: _isCredit,
                onChanged: (value) {
                  setState(() {
                    _isCredit = value!;
                  });
                },
              ),
              
              // VAT (Only for income)
              if (_transactionType == 'income')
                CheckboxListTile(
                  title: Text('Add 7.5% VAT'),
                  subtitle: Text('Value Added Tax'),
                  value: _addVat,
                  onChanged: (value) {
                    setState(() {
                      _addVat = value!;
                    });
                  },
                ),
              
              SizedBox(height: 16),
              
              // Receipt Image
              if (_receiptImagePath != null)
                Image.network(_receiptImagePath!, height: 150)
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera);
                    
                    if (image != null) {
                      setState(() {
                        _receiptImagePath = image.path;
                      });
                    }
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text('Take Receipt Photo'),
                ),
              
              SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final vatAmount = _addVat ? amount * 0.075 : 0.0;
      final totalAmount = _addVat ? amount + vatAmount : amount;
      
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate,
        amount: totalAmount,
        type: _transactionType,
        category: _category,
        description: _descriptionController.text,
        paymentMethod: _paymentMethod,
        contactName: _contactNameController.text.isEmpty ? null : _contactNameController.text,
        isCredit: _isCredit,
        vatAmount: vatAmount,
        receiptImagePath: _receiptImagePath,
      );
      
      Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction added successfully!'))
      );
      
      Navigator.pop(context);
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }
}