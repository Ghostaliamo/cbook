// providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cbook/models/transaction.dart';
import 'package:cbook/models/contact.dart';
import 'package:cbook/services/firebase_service.dart';
import 'package:cbook/providers/business_book_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TransactionProvider with ChangeNotifier {
  final Map<String, List<Transaction>> _transactionsByBook = {};
  final Map<String, List<Contact>> _contactsByBook = {};
  final Map<String, List<Transaction>> _pendingTransactions = {};
  final Map<String, List<Contact>> _pendingContacts = {};
  
  final FirebaseService _firebaseService;
  final BusinessBookProvider _businessBookProvider;
  final Connectivity _connectivity = Connectivity();
  
  String? get _currentBookId => _businessBookProvider.currentBook?.id;
  
  bool _isLoading = false;
  bool _isCloudConnected = true;
  String? _lastError;

  TransactionProvider(this._businessBookProvider) : _firebaseService = FirebaseService() {
    _businessBookProvider.addListener(_onBookChanged);
    _setupConnectivityListener();
    
    // Load data when provider is created
    if (_currentBookId != null) {
      loadCurrentBookData();
    }
  }

  @override
  void dispose() {
    _businessBookProvider.removeListener(_onBookChanged);
    super.dispose();
  }

  // Getters for state management
  bool get isLoading => _isLoading;
  bool get isCloudConnected => _isCloudConnected;
  String? get lastError => _lastError;
  bool get hasPendingChanges => _pendingTransactions.isNotEmpty || _pendingContacts.isNotEmpty;

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _lastError = null; // Clear error when starting new operation
    }
    notifyListeners();
  }

  Future<void> _setupConnectivityListener() async {
    _connectivity.onConnectivityChanged.listen((result) async {
      final wasConnected = _isCloudConnected;
      _isCloudConnected = result != ConnectivityResult.none;
      
      if (!wasConnected && _isCloudConnected) {
        // Reconnected to internet, sync pending changes
        print('Reconnected to internet, syncing pending changes...');
        await _syncPendingChanges();
      }
      
      notifyListeners();
    });
  }

  void _onBookChanged() {
    if (_currentBookId != null) {
      loadCurrentBookData();
    }
    notifyListeners();
  }

  // Get transactions for current book
  List<Transaction> get transactions {
    if (_currentBookId == null) return [];
    
    try {
      final bookTransactions = _transactionsByBook[_currentBookId] ?? [];
      final pending = _pendingTransactions[_currentBookId] ?? [];
      
      // Combine regular and pending transactions
      return [...bookTransactions, ...pending].toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }
  
  List<Transaction> get reversedTransactions {
    return transactions.reversed.toList();
  }
  
  List<Transaction> get incomeTransactions {
    return transactions.where((t) => t.isIncome).toList();
  }
  
  List<Transaction> get expenseTransactions {
    return transactions.where((t) => t.isExpense).toList();
  }
  
  // Get contacts for current book (including pending changes)
  List<Contact> get debtors {
    if (_currentBookId == null) return [];
    
    try {
      final bookContacts = _contactsByBook[_currentBookId] ?? [];
      final pendingContacts = _pendingContacts[_currentBookId] ?? [];
      
      // Combine regular and pending contacts
      final allContacts = [...bookContacts, ...pendingContacts];
      
      return allContacts
          .where((c) => c.isDebtor && c.balance > 0)
          .toList();
    } catch (e) {
      debugPrint('Error getting debtors: $e');
      return [];
    }
  }
  
  List<Contact> get creditors {
    if (_currentBookId == null) return [];
    
    try {
      final bookContacts = _contactsByBook[_currentBookId] ?? [];
      final pendingContacts = _pendingContacts[_currentBookId] ?? [];
      
      // Combine regular and pending contacts
      final allContacts = [...bookContacts, ...pendingContacts];
      
      return allContacts
          .where((c) => c.isCreditor && c.balance > 0)
          .toList();
    } catch (e) {
      debugPrint('Error getting creditors: $e');
      return [];
    }
  }
  
  List<Contact> get allContacts {
    if (_currentBookId == null) return [];
    
    try {
      final bookContacts = _contactsByBook[_currentBookId] ?? [];
      final pendingContacts = _pendingContacts[_currentBookId] ?? [];
      
      return [...bookContacts, ...pendingContacts].toList();
    } catch (e) {
      debugPrint('Error getting contacts: $e');
      return [];
    }
  }
  
  // Monthly summary getter
  Map<String, double> get monthlySummary {
    if (_currentBookId == null) {
      return {'income': 0, 'expense': 0, 'vat': 0};
    }
    
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    
    final monthTransactions = getTransactionsByDateRange(firstDay, lastDay);
    
    final Map<String, double> summary = {
      'income': 0,
      'expense': 0,
      'vat': 0,
    };

    for (final transaction in monthTransactions) {
      if (transaction.isIncome) {
        summary['income'] = summary['income']! + transaction.amount;
      } else {
        summary['expense'] = summary['expense']! + transaction.amount;
      }
      summary['vat'] = summary['vat']! + (transaction.vatAmount ?? 0);
    }

    return summary;
  }

  // Financial health getter
  Map<String, dynamic> get financialHealth {
    final income = totalIncome;
    final expenses = totalExpenses;
    final netProfitValue = netProfit;
    
    final profitMargin = income > 0 ? (netProfitValue / income) * 100 : 0;
    final debtToIncome = income > 0 ? (totalDebts / income) * 100 : 0;
    
    return {
      'profitMargin': profitMargin,
      'debtToIncomeRatio': debtToIncome,
      'cashFlow': netProfitValue,
      'isHealthy': profitMargin > 10 && debtToIncome < 30,
    };
  }

  double get totalIncome {
    if (_currentBookId == null) return 0;
    return incomeTransactions.fold(0, (sum, item) => sum + item.amount);
  }
  
  double get totalExpenses {
    if (_currentBookId == null) return 0;
    return expenseTransactions.fold(0, (sum, item) => sum + item.amount);
  }
  
  double get netProfit {
    return totalIncome - totalExpenses;
  }
  
  double get totalDebts {
    if (_currentBookId == null) return 0;
    return debtors.fold(0, (sum, item) => sum + item.balance);
  }
  
  double get totalCredits {
    if (_currentBookId == null) return 0;
    return creditors.fold(0, (sum, item) => sum + item.balance);
  }
  
  double get totalVatCollected {
    if (_currentBookId == null) return 0;
    return transactions.fold(0, (sum, item) => sum + (item.vatAmount ?? 0));
  }

  // Initialize data for a new book
  void _initializeBookData(String bookId) {
    if (!_transactionsByBook.containsKey(bookId)) {
      _transactionsByBook[bookId] = [];
    }
    
    if (!_contactsByBook.containsKey(bookId)) {
      _contactsByBook[bookId] = [];
    }
    
    if (!_pendingTransactions.containsKey(bookId)) {
      _pendingTransactions[bookId] = [];
    }
    
    if (!_pendingContacts.containsKey(bookId)) {
      _pendingContacts[bookId] = [];
    }
  }

  // Load data for current book from Firestore
  Future<void> loadCurrentBookData() async {
    if (_currentBookId == null) return;
    
    _setLoading(true);
    _lastError = null;
    
    try {
      _initializeBookData(_currentBookId!);
      
      if (_isCloudConnected) {
        // Load from Firestore if connected
        try {
          final transactions = await _firebaseService.fetchTransactionsFromCloud(_currentBookId!);
          _transactionsByBook[_currentBookId!] = transactions;
          debugPrint('Loaded ${transactions.length} transactions from cloud');
        } catch (e) {
          debugPrint('Error loading transactions from cloud: $e');
          // Continue with empty transactions if permission denied
          _transactionsByBook[_currentBookId!] = [];
        }
        
        try {
          final contacts = await _firebaseService.fetchContactsFromCloud(_currentBookId!);
          _contactsByBook[_currentBookId!] = contacts;
          debugPrint('Loaded ${contacts.length} contacts from cloud');
        } catch (e) {
          debugPrint('Error loading contacts from cloud: $e');
          // Continue with empty contacts if permission denied
          _contactsByBook[_currentBookId!] = [];
        }
      } else {
        debugPrint('Using local data (offline mode)');
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error loading book data: $e';
      debugPrint('Error loading book data: $e');
      
      // If cloud load fails but we have local data, use it
      if (_transactionsByBook[_currentBookId!]?.isNotEmpty ?? false) {
        debugPrint('Using existing local data due to cloud error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get transactions for a specific date range
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    if (_currentBookId == null) return [];
    
    return transactions.where((t) => 
      t.date.isAfter(start.subtract(const Duration(days: 1))) && 
      t.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // Get recent transactions (last 7 days)
  List<Transaction> get recentTransactions {
    if (_currentBookId == null) return [];
    
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return transactions.where((t) => t.date.isAfter(weekAgo)).toList();
  }

  // Add transaction with offline support
  Future<void> addTransaction(Transaction transaction) async {
    if (_currentBookId == null) {
      _lastError = 'Cannot add transaction: no current book';
      debugPrint('Cannot add transaction: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      _initializeBookData(_currentBookId!);
      
      if (_isCloudConnected) {
        // Online mode: add directly and sync to Firestore
        _transactionsByBook[_currentBookId]!.add(transaction);
        
        // If it's a credit transaction, update contact balance
        if (transaction.isCredit && transaction.contactName != null) {
          await _updateContactBalance(transaction);
        }
        
        // Sync to Firestore
        try {
          await _firebaseService.saveTransactionToCloud(_currentBookId!, transaction);
          debugPrint('Transaction synced to Firestore successfully');
        } catch (e) {
          debugPrint('Firestore sync error: $e');
          // Revert the local change if Firestore sync fails
          _transactionsByBook[_currentBookId]!.remove(transaction);
          if (transaction.isCredit && transaction.contactName != null) {
            await _reverseContactBalance(transaction);
          }
          rethrow;
        }
      } else {
        // Offline mode: add to pending changes
        _pendingTransactions[_currentBookId]!.add(transaction);
        
        // If it's a credit transaction, update contact balance (pending)
        if (transaction.isCredit && transaction.contactName != null) {
          await _updateContactBalance(transaction, isPending: true);
        }
        
        debugPrint('Transaction added to pending changes (offline mode)');
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error adding transaction: $e';
      debugPrint('Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update contact balance for credit transactions
  Future<void> _updateContactBalance(Transaction transaction, {bool isPending = false}) async {
    if (_currentBookId == null) return;
    
    final contactId = '${transaction.type}_${transaction.contactName!.toLowerCase().replaceAll(' ', '_')}';
    
    try {
      _initializeBookData(_currentBookId!);
      
      final contacts = isPending ? _pendingContacts : _contactsByBook;
      final contactList = contacts[_currentBookId]!;
      
      final existingContactIndex = contactList.indexWhere((c) => c.id == contactId);
      
      if (existingContactIndex != -1) {
        final existingContact = contactList[existingContactIndex];
        final newBalance = transaction.isIncome
          ? existingContact.balance + transaction.amount
          : existingContact.balance - transaction.amount;
        
        final updatedContact = existingContact.copyWith(balance: newBalance);
        contactList[existingContactIndex] = updatedContact;
        
        if (!isPending && _isCloudConnected) {
          // Sync contact to Firestore if online
          try {
            await _firebaseService.updateContactInCloud(_currentBookId!, updatedContact);
          } catch (e) {
            debugPrint('Firestore contact sync error: $e');
            // Revert the local change if Firestore sync fails
            contactList[existingContactIndex] = existingContact;
            rethrow;
          }
        }
      } else {
        final newContact = Contact(
          id: contactId,
          name: transaction.contactName!,
          type: transaction.isIncome ? 'debtor' : 'creditor',
          balance: transaction.isIncome ? transaction.amount : -transaction.amount,
        );
        
        contactList.add(newContact);
        
        if (!isPending && _isCloudConnected) {
          // Sync new contact to Firestore if online
          try {
            await _firebaseService.saveContactToCloud(_currentBookId!, newContact);
          } catch (e) {
            debugPrint('Firestore contact sync error: $e');
            // Revert the local change if Firestore sync fails
            contactList.remove(newContact);
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating contact balance: $e');
      throw Exception('Failed to update contact balance: $e');
    }
  }

  // Delete transaction with offline support
  Future<void> deleteTransaction(String transactionId) async {
    if (_currentBookId == null) {
      _lastError = 'Cannot delete transaction: no current book';
      debugPrint('Cannot delete transaction: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      _initializeBookData(_currentBookId!);
      
      // Check both regular and pending transactions
      final regularIndex = _transactionsByBook[_currentBookId]!.indexWhere((t) => t.id == transactionId);
      final pendingIndex = _pendingTransactions[_currentBookId]!.indexWhere((t) => t.id == transactionId);
      
      if (regularIndex == -1 && pendingIndex == -1) {
        throw Exception('Transaction not found');
      }
      
      Transaction? transaction;
      bool isPending = false;
      
      if (regularIndex != -1) {
        transaction = _transactionsByBook[_currentBookId]![regularIndex];
        _transactionsByBook[_currentBookId]!.removeAt(regularIndex);
      } else {
        transaction = _pendingTransactions[_currentBookId]![pendingIndex];
        _pendingTransactions[_currentBookId]!.removeAt(pendingIndex);
        isPending = true;
      }
      
      if (transaction != null && transaction.isCredit && transaction.contactName != null) {
        await _reverseContactBalance(transaction, isPending: isPending);
      }
      
      if (_isCloudConnected && !isPending) {
        // Delete from Firestore if online and not a pending transaction
        try {
          await _firebaseService.deleteTransactionFromCloud(_currentBookId!, transactionId);
          debugPrint('Transaction deleted from Firestore successfully');
        } catch (e) {
          debugPrint('Firestore delete error: $e');
          // Revert the local change if Firestore sync fails
          if (regularIndex != -1) {
            _transactionsByBook[_currentBookId]!.insert(regularIndex, transaction!);
          }
          if (transaction!.isCredit && transaction.contactName != null) {
            await _updateContactBalance(transaction);
          }
          rethrow;
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error deleting transaction: $e';
      debugPrint('Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reverse contact balance when transaction is deleted
  Future<void> _reverseContactBalance(Transaction transaction, {bool isPending = false}) async {
    if (_currentBookId == null) return;
    
    final contactId = '${transaction.type}_${transaction.contactName!.toLowerCase().replaceAll(' ', '_')}';
    _initializeBookData(_currentBookId!);
    
    final contacts = isPending ? _pendingContacts : _contactsByBook;
    final contactList = contacts[_currentBookId]!;
    
    final contactIndex = contactList.indexWhere((c) => c.id == contactId);
    
    if (contactIndex != -1) {
      final contact = contactList[contactIndex];
      final newBalance = transaction.isIncome
        ? contact.balance - transaction.amount
        : contact.balance + transaction.amount;
      
      final updatedContact = contact.copyWith(balance: newBalance);
      contactList[contactIndex] = updatedContact;
      
      if (!isPending && _isCloudConnected) {
        // Sync updated contact to Firestore if online
        try {
          await _firebaseService.updateContactInCloud(_currentBookId!, updatedContact);
        } catch (e) {
          debugPrint('Firestore contact sync error: $e');
          // Revert the local change if Firestore sync fails
          contactList[contactIndex] = contact;
          rethrow;
        }
      }
    }
  }

  // Update transaction with offline support
  Future<void> updateTransaction(Transaction updatedTransaction) async {
    if (_currentBookId == null) {
      _lastError = 'Cannot update transaction: no current book';
      debugPrint('Cannot update transaction: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      _initializeBookData(_currentBookId!);
      
      // Check both regular and pending transactions
      final regularIndex = _transactionsByBook[_currentBookId]!.indexWhere((t) => t.id == updatedTransaction.id);
      final pendingIndex = _pendingTransactions[_currentBookId]!.indexWhere((t) => t.id == updatedTransaction.id);
      
      if (regularIndex == -1 && pendingIndex == -1) {
        throw Exception('Transaction not found');
      }
      
      final bool isPending = regularIndex == -1;
      final int index = isPending ? pendingIndex : regularIndex;
      
      final oldTransaction = isPending 
        ? _pendingTransactions[_currentBookId]![index]
        : _transactionsByBook[_currentBookId]![index];
      
      // Store the original state for potential rollback
      final originalTransaction = isPending
        ? _pendingTransactions[_currentBookId]![index]
        : _transactionsByBook[_currentBookId]![index];
      
      if (oldTransaction.isCredit && oldTransaction.contactName != null) {
        await _reverseContactBalance(oldTransaction, isPending: isPending);
      }

      if (isPending) {
        _pendingTransactions[_currentBookId]![index] = updatedTransaction;
      } else {
        _transactionsByBook[_currentBookId]![index] = updatedTransaction;
      }
      
      if (updatedTransaction.isCredit && updatedTransaction.contactName != null) {
        await _updateContactBalance(updatedTransaction, isPending: isPending);
      }
      
      if (_isCloudConnected && !isPending) {
        // Sync to Firestore if online and not a pending transaction
        try {
          await _firebaseService.updateTransactionInCloud(_currentBookId!, updatedTransaction);
          debugPrint('Transaction updated in Firestore successfully');
        } catch (e) {
          debugPrint('Firestore update error: $e');
          // Revert the local changes if Firestore sync fails
          if (isPending) {
            _pendingTransactions[_currentBookId]![index] = originalTransaction;
          } else {
            _transactionsByBook[_currentBookId]![index] = originalTransaction;
          }
          if (oldTransaction.isCredit && oldTransaction.contactName != null) {
            await _updateContactBalance(oldTransaction, isPending: isPending);
          }
          if (updatedTransaction.isCredit && updatedTransaction.contactName != null) {
            await _reverseContactBalance(updatedTransaction, isPending: isPending);
          }
          rethrow;
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error updating transaction: $e';
      debugPrint('Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sync pending changes when connectivity is restored
  Future<void> _syncPendingChanges() async {
    if (_currentBookId == null || !_isCloudConnected) return;
    
    _setLoading(true);
    
    try {
      // Sync pending transactions
      final pendingTransactions = List<Transaction>.from(_pendingTransactions[_currentBookId] ?? []);
      for (final transaction in pendingTransactions) {
        try {
          await _firebaseService.saveTransactionToCloud(_currentBookId!, transaction);
          
          // Move from pending to regular
          _transactionsByBook[_currentBookId]!.add(transaction);
          _pendingTransactions[_currentBookId]!.remove(transaction);
          
        } catch (e) {
          debugPrint('Failed to sync transaction ${transaction.id}: $e');
          // Keep in pending for retry
        }
      }
      
      // Sync pending contacts
      final pendingContacts = List<Contact>.from(_pendingContacts[_currentBookId] ?? []);
      for (final contact in pendingContacts) {
        try {
          await _firebaseService.saveContactToCloud(_currentBookId!, contact);
          
          // Move from pending to regular or update existing
          final existingIndex = _contactsByBook[_currentBookId]!.indexWhere((c) => c.id == contact.id);
          if (existingIndex != -1) {
            _contactsByBook[_currentBookId]![existingIndex] = contact;
            _pendingContacts[_currentBookId]!.remove(contact);
          } else {
            _contactsByBook[_currentBookId]!.add(contact);
            _pendingContacts[_currentBookId]!.remove(contact);
          }
          
        } catch (e) {
          debugPrint('Failed to sync contact ${contact.id}: $e');
          // Keep in pending for retry
        }
      }
      
      debugPrint('Pending changes synced successfully');
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error syncing pending changes: $e';
      debugPrint('Error syncing pending changes: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Manual sync method
  Future<void> syncPendingChanges() async {
    await _syncPendingChanges();
  }

  // Get transactions for a specific contact
  List<Transaction> getTransactionsForContact(String contactName) {
    return transactions.where((t) => t.contactName == contactName).toList();
  }

  // Get transactions by category
  Map<String, double> getTransactionsByCategory(String type) {
    final filteredTransactions = type == 'income' ? incomeTransactions : expenseTransactions;
    final Map<String, double> categoryMap = {};
    
    for (final transaction in filteredTransactions) {
      categoryMap.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount
      );
    }
    
    return categoryMap;
  }

  // Search transactions
  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return transactions;
    
    final lowercaseQuery = query.toLowerCase();
    return transactions.where((t) =>
      t.description.toLowerCase().contains(lowercaseQuery) ||
      (t.contactName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
      t.category.toLowerCase().contains(lowercaseQuery) ||
      t.amount.toString().contains(lowercaseQuery) ||
      DateFormat('yyyy-MM-dd').format(t.date).toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Clear all data for current book
  Future<void> clearCurrentBookData() async {
    if (_currentBookId == null) {
      debugPrint('Cannot clear data: no current book');
      return;
    }
    
    _setLoading(true);
    
    try {
      _transactionsByBook[_currentBookId]?.clear();
      _contactsByBook[_currentBookId]?.clear();
      _pendingTransactions[_currentBookId]?.clear();
      _pendingContacts[_currentBookId]?.clear();
      
      if (_isCloudConnected) {
        // Clear Firestore data if online
        try {
          await _firebaseService.clearBookDataFromCloud(_currentBookId!);
          debugPrint('Book data cleared from Firestore');
        } catch (e) {
          debugPrint('Firestore clear error: $e');
          rethrow;
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error clearing data: $e';
      debugPrint('Error clearing data: $e');
      throw Exception('Failed to clear data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Export data as CSV string
  String exportToCsv() {
    final csv = StringBuffer();
    // Add header row
    csv.writeln('Date,Type,Amount,Category,Description,Payment Method,Contact Name,VAT Amount,Total Amount');
    
    // Add transaction rows
    for (final transaction in transactions) {
      csv.writeln([
        DateFormat('yyyy-MM-dd HH:mm').format(transaction.date),
        transaction.type,
        transaction.amount.toStringAsFixed(2),
        transaction.category,
        '"${transaction.description.replaceAll('"', '""')}"', // Escape quotes in description
        transaction.paymentMethod,
        transaction.contactName ?? '',
        transaction.vatAmount?.toStringAsFixed(2) ?? '0.00',
        transaction.totalAmount.toStringAsFixed(2),
      ].join(','));
    }
    
    return csv.toString();
  }

  // Export data as PDF file
  Future<File> exportToPdf() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text('CBook Transaction Report',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}'),
              pw.Text('Total Transactions: ${transactions.length}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Summary section
              pw.Text('Financial Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Income:'),
                  pw.Text('\₦${totalIncome.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Expenses:'),
                  pw.Text('\₦${totalExpenses.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Net Profit:'),
                  pw.Text('\₦${netProfit.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total VAT Collected:'),
                  pw.Text('\₦${totalVatCollected.toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Transactions table
              pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              if (transactions.isNotEmpty)
                pw.Table.fromTextArray(
                  context: context,
                  border: null,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerLeft,
                    4: pw.Alignment.centerLeft,
                  },
                  data: [
                    ['Date', 'Type', 'Amount', 'Category', 'Description'],
                    ...transactions.map((transaction) => [
                      DateFormat('yyyy-MM-dd').format(transaction.date),
                      transaction.type,
                      '\₦${transaction.amount.toStringAsFixed(2)}',
                      transaction.category,
                      transaction.description,
                    ]).toList()
                  ],
                )
              else
                pw.Text('No transactions found'),
            ],
          );
        },
      ),
    );

    // Save the PDF to a temporary file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/cbook_export_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Get Nigerian business insights
  Map<String, dynamic> get nigerianBusinessInsights {
    final vatCompliance = totalVatCollected > 0;
    final avgTransaction = transactions.isNotEmpty ? totalIncome / transactions.length : 0;
    
    return {
      'vatCompliant': vatCompliance,
      'averageTransaction': avgTransaction,
      'totalVatObligation': totalVatCollected,
      'suggestedVatPayment': vatCompliance ? 'Ensure VAT remittance to FIRS' : 'Consider enabling VAT on sales',
    };
  }

  // Sync all data to Firestore for current book
  Future<void> _syncCurrentBookDataToCloud() async {
    if (_currentBookId == null) {
      debugPrint('Cannot sync: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      // Sync transactions
      for (final transaction in _transactionsByBook[_currentBookId]!) {
        await _firebaseService.saveTransactionToCloud(_currentBookId!, transaction);
      }
      
      // Sync contacts
      for (final contact in _contactsByBook[_currentBookId]!) {
        await _firebaseService.saveContactToCloud(_currentBookId!, contact);
      }
      
      debugPrint('Current book data synced to Firestore');
      
    } catch (e) {
      _lastError = 'Error syncing current book data: $e';
      debugPrint('Error syncing current book data: $e');
      throw Exception('Failed to sync current book data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Implement the missing methods with enhanced error handling
  Future<void> receivePayment(String contactId, double amount, String selectedPaymentMethod) async {
    if (_currentBookId == null) {
      _lastError = 'Cannot receive payment: no current book';
      debugPrint('Cannot receive payment: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      final contacts = [..._contactsByBook[_currentBookId]!, ..._pendingContacts[_currentBookId]!];
      final contactIndex = contacts.indexWhere((c) => c.id == contactId);
      
      if (contactIndex == -1) {
        throw Exception('Contact not found');
      }
      
      final contact = contacts[contactIndex];
      if (contact.balance < amount) {
        throw Exception('Payment amount exceeds debt');
      }
      
      final updatedContact = contact.copyWith(balance: contact.balance - amount);
      
      // Update in appropriate list
      if (contactIndex < _contactsByBook[_currentBookId]!.length) {
        _contactsByBook[_currentBookId]![contactIndex] = updatedContact;
      } else {
        final pendingIndex = contactIndex - _contactsByBook[_currentBookId]!.length;
        _pendingContacts[_currentBookId]![pendingIndex] = updatedContact;
      }
      
      // Create a transaction for the payment
      final paymentTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        amount: amount,
        type: 'payment_received',
        category: 'Payment Received',
        description: 'Payment received from ${contact.name}',
        paymentMethod: selectedPaymentMethod,
        contactName: contact.name,
      );
      
      await addTransaction(paymentTransaction);
      
      if (_isCloudConnected) {
        // Sync contact to Firestore if online
        await _firebaseService.updateContactInCloud(_currentBookId!, updatedContact);
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error receiving payment: $e';
      debugPrint('Error receiving payment: $e');
      throw Exception('Failed to receive payment: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> payCreditor(String contactId, double amount, String selectedPaymentMethod) async {
    if (_currentBookId == null) {
      _lastError = 'Cannot pay creditor: no current book';
      debugPrint('Cannot pay creditor: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      final contacts = [..._contactsByBook[_currentBookId]!, ..._pendingContacts[_currentBookId]!];
      final contactIndex = contacts.indexWhere((c) => c.id == contactId);
      
      if (contactIndex == -1) {
        throw Exception('Contact not found');
      }
      
      final contact = contacts[contactIndex];
      if (contact.balance > -amount) {
        throw Exception('Payment amount exceeds credit');
      }
      
      final updatedContact = contact.copyWith(balance: contact.balance + amount);
      
      // Update in appropriate list
      if (contactIndex < _contactsByBook[_currentBookId]!.length) {
        _contactsByBook[_currentBookId]![contactIndex] = updatedContact;
      } else {
        final pendingIndex = contactIndex - _contactsByBook[_currentBookId]!.length;
        _pendingContacts[_currentBookId]![pendingIndex] = updatedContact;
      }
      
      // Create a transaction for the payment
      final paymentTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        amount: amount,
        type: 'payment_made',
        category: 'Payment Made',
        description: 'Payment made to ${contact.name}',
        paymentMethod: selectedPaymentMethod,
        contactName: contact.name,
      );
      
      await addTransaction(paymentTransaction);
      
      if (_isCloudConnected) {
        // Sync contact to Firestore if online
        await _firebaseService.updateContactInCloud(_currentBookId!, updatedContact);
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error paying creditor: $e';
      debugPrint('Error paying creditor: $e');
      throw Exception('Failed to pay creditor: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    if (_currentBookId == null) {
      _lastError = 'Cannot restore backup: no current book';
      debugPrint('Cannot restore backup: no current book');
      throw Exception('No current book selected');
    }
    
    _setLoading(true);
    
    try {
      final transactions = (backupData['transactions'] as List)
          .map((t) => Transaction.fromMap(t))
          .toList();
      final contacts = (backupData['contacts'] as List)
          .map((c) => Contact.fromMap(c))
          .toList();
      
      _transactionsByBook[_currentBookId!] = transactions;
      _contactsByBook[_currentBookId!] = contacts;
      _pendingTransactions[_currentBookId!]?.clear();
      _pendingContacts[_currentBookId!]?.clear();
      
      // Sync to Firestore if online
      if (_isCloudConnected) {
        await _syncCurrentBookDataToCloud();
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error restoring from backup: $e';
      debugPrint('Error restoring from backup: $e');
      throw Exception('Failed to restore from backup: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeBookData(String bookId) async {
  _setLoading(true);
  
  try {
    _transactionsByBook.remove(bookId);
    _contactsByBook.remove(bookId);
    _pendingTransactions.remove(bookId);
    _pendingContacts.remove(bookId);
    
    if (_isCloudConnected) {
      // Remove from Firestore if online
      try {
        await _firebaseService.removeBookDataFromCloud(bookId);
        debugPrint('Book data removed from Firestore');
      } catch (e) {
        debugPrint('Firestore remove error: $e');
        rethrow;
      }
    }
    
    notifyListeners();
    
  } catch (e) {
    _lastError = 'Error removing book data: $e';
    debugPrint('Error removing book data: $e');
    throw Exception('Failed to remove book data: $e');
  } finally {
    _setLoading(false);
  }
}

  Future<void> clearAllData() async {
    _setLoading(true);
    
    try {
      _transactionsByBook.clear();
      _contactsByBook.clear();
      _pendingTransactions.clear();
      _pendingContacts.clear();
      
      if (_isCloudConnected) {
        // Clear all Firestore data if online
        for (final bookId in _transactionsByBook.keys) {
          await _firebaseService.clearBookDataFromCloud(bookId);
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error clearing all data: $e';
      debugPrint('Error clearing all data: $e');
      throw Exception('Failed to clear all data: $e');
    } finally {
      _setLoading(false);
    }
  }
}