// models/transaction.dart
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String description;
  final String paymentMethod; // 'cash', 'transfer', 'pos'
  final String? contactName;
  final bool isCredit;
  final double? vatAmount;
  final String? receiptImagePath;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.paymentMethod,
    this.contactName,
    this.isCredit = false,
    this.vatAmount,
    this.receiptImagePath,
  });

  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
  
  String get formattedAmount {
    return '₦${amount.toStringAsFixed(2)}';
  }
  
  String get formattedVat {
    return vatAmount != null ? '₦${vatAmount!.toStringAsFixed(2)}' : '₦0.00';
  }

  // Convert Transaction to Map for Firebase/Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod,
      'contactName': contactName,
      'isCredit': isCredit,
      'vatAmount': vatAmount,
      'receiptImagePath': receiptImagePath,
    };
  }

  // Create Transaction from Map (for Firebase/Firestore)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: map['date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      contactName: map['contactName'],
      isCredit: map['isCredit'] ?? false,
      vatAmount: map['vatAmount'] != null ? (map['vatAmount'] as num).toDouble() : null,
      receiptImagePath: map['receiptImagePath'],
    );
  }

  // Helper method to create a copy with updated fields
  Transaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? type,
    String? category,
    String? description,
    String? paymentMethod,
    String? contactName,
    bool? isCredit,
    double? vatAmount,
    String? receiptImagePath,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      contactName: contactName ?? this.contactName,
      isCredit: isCredit ?? this.isCredit,
      vatAmount: vatAmount ?? this.vatAmount,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    );
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'Transaction{id: $id, date: $date, amount: $amount, type: $type, category: $category, description: $description}';
  }

  // Override equality for comparing transactions
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper method to check if transaction is income
  bool get isIncome => type == 'income';

  // Helper method to check if transaction is expense
  bool get isExpense => type == 'expense';

  // Get total amount including VAT
  double get totalAmount {
    if (vatAmount != null && vatAmount! > 0) {
      return amount + vatAmount!;
    }
    return amount;
  }

  // Formatted total amount including VAT
  String get formattedTotalAmount {
    return '₦${totalAmount.toStringAsFixed(2)}';
  }

  // Nigerian-style formatted amount with thousands separators
  String get formattedAmountWithCommas {
    final formatter = NumberFormat('#,##0.00');
    return '₦${formatter.format(amount)}';
  }

  // Get VAT percentage (7.5% for Nigeria)
  double get vatPercentage {
    return 7.5;
  }

  // Calculate VAT amount from base amount
  static double calculateVat(double amount) {
    return amount * 0.075;
  }

  // Create a new transaction with VAT calculated
  Transaction withVat() {
    if (vatAmount != null && vatAmount! > 0) {
      return this;
    }
    return copyWith(
      vatAmount: calculateVat(amount),
    );
  }

  // Create a new transaction without VAT
  Transaction withoutVat() {
    return copyWith(vatAmount: 0);
  }
}