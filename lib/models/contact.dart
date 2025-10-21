// models/contact.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Contact {
  final String id;
  final String name;
  final String type; // 'debtor' or 'creditor'
  final String? phoneNumber;
  final String? email;
  final double balance;
  final DateTime createdAt;
  final DateTime? lastTransactionDate;
  final String? address;
  final String? businessName;
  final String? notes;

  Contact({
    required this.id,
    required this.name,
    required this.type,
    this.phoneNumber,
    this.email,
    this.balance = 0.0,
    DateTime? createdAt,
    this.lastTransactionDate,
    this.address,
    this.businessName,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedBalance {
    return '₦${balance.toStringAsFixed(2)}';
  }

  // Convert Contact to Map for Firebase/Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phoneNumber': phoneNumber,
      'email': email,
      'balance': balance,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastTransactionDate': lastTransactionDate?.millisecondsSinceEpoch,
      'address': address,
      'businessName': businessName,
      'notes': notes,
    };
  }

  // Create Contact from Map (for Firebase/Firestore)
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? 'Unknown Contact',
      type: map['type'] ?? 'debtor',
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      lastTransactionDate: map['lastTransactionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTransactionDate'])
          : null,
      address: map['address'],
      businessName: map['businessName'],
      notes: map['notes'],
    );
  }

  // Helper method to create a copy with updated fields
  Contact copyWith({
    String? id,
    String? name,
    String? type,
    String? phoneNumber,
    String? email,
    double? balance,
    DateTime? createdAt,
    DateTime? lastTransactionDate,
    String? address,
    String? businessName,
    String? notes,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      address: address ?? this.address,
      businessName: businessName ?? this.businessName,
      notes: notes ?? this.notes,
    );
  }

  // Update last transaction date
  Contact withTransactionUpdate() {
    return copyWith(lastTransactionDate: DateTime.now());
  }

  // Update balance
  Contact withBalanceUpdate(double newBalance) {
    return copyWith(
      balance: newBalance,
      lastTransactionDate: DateTime.now(),
    );
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'Contact{id: $id, name: $name, type: $type, balance: $balance, phone: $phoneNumber}';
  }

  // Override equality for comparing contacts
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper method to check if contact is a debtor
  bool get isDebtor => type == 'debtor';

  // Helper method to check if contact is a creditor
  bool get isCreditor => type == 'creditor';

  // Nigerian-style formatted balance with thousands separators
  String get formattedBalanceWithCommas {
    final formatter = NumberFormat('#,##0.00');
    return '₦${formatter.format(balance)}';
  }

  // Get balance status (positive, negative, zero)
  String get balanceStatus {
    if (balance > 0) {
      return isDebtor ? 'Owes you' : 'You owe';
    } else if (balance < 0) {
      return isDebtor ? 'Overpaid' : 'Credit balance';
    } else {
      return 'Settled';
    }
  }

  // Get balance color for UI
  Color get balanceColor {
    if (balance > 0) {
      return isDebtor ? Colors.green : Colors.red;
    } else if (balance < 0) {
      return isDebtor ? Colors.red : Colors.green;
    } else {
      return Colors.grey;
    }
  }

  // Get balance icon for UI
  IconData get balanceIcon {
    if (balance > 0) {
      return isDebtor ? Icons.arrow_circle_down : Icons.arrow_circle_up;
    } else if (balance < 0) {
      return isDebtor ? Icons.arrow_circle_up : Icons.arrow_circle_down;
    } else {
      return Icons.check_circle;
    }
  }

  // Days since last transaction
  int get daysSinceLastTransaction {
    if (lastTransactionDate == null) return 0;
    final now = DateTime.now();
    return now.difference(lastTransactionDate!).inDays;
  }

  // Get transaction recency status
  String get transactionRecency {
    final days = daysSinceLastTransaction;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} weeks ago';
    return '${(days / 30).floor()} months ago';
  }

  // Check if contact is active (transaction in last 30 days)
  bool get isActive {
    return daysSinceLastTransaction <= 30;
  }

  // Check if debt is overdue (more than 30 days for debtors with positive balance)
  bool get isOverdue {
    return isDebtor && balance > 0 && daysSinceLastTransaction > 30;
  }

  // Get overdue status text
  String get overdueStatus {
    if (!isOverdue) return 'Current';
    final days = daysSinceLastTransaction;
    if (days <= 60) return '30+ days overdue';
    if (days <= 90) return '60+ days overdue';
    return '90+ days overdue';
  }

  // Get Nigerian phone number format
  String? get formattedPhoneNumber {
    if (phoneNumber == null) return null;
    // Format Nigerian phone numbers (08012345678 -> 0801 234 5678)
    final cleaned = phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 11 && cleaned.startsWith('0')) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    return phoneNumber;
  }

  // Get contact type display name
  String get typeDisplayName {
    return isDebtor ? 'Customer' : 'Supplier';
  }

  // Get initial for avatar
  String get initial {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  // Check if contact has complete information
  bool get hasCompleteInfo {
    return phoneNumber != null && phoneNumber!.isNotEmpty && 
           email != null && email!.isNotEmpty &&
           address != null && address!.isNotEmpty;
  }

  // Get contact rating based on activity and payment history
  double get rating {
    // Simple rating based on activity and balance status
    double rating = 3.0; // Base rating
    
    // Positive points for active contacts
    if (isActive) rating += 1.0;
    
    // Positive points for settled balances
    if (balance == 0) rating += 1.0;
    
    // Negative points for overdue debts
    if (isOverdue) rating -= 1.0;
    
    // Negative points for large overdue debts
    if (isOverdue && balance > 10000) rating -= 1.0;
    
    return rating.clamp(1.0, 5.0);
  }

  // Get rating stars for UI
  String get ratingStars {
    final stars = '⭐' * rating.round();
    return stars;
  }

  // Get contact category based on balance and activity
  String get category {
    if (balance == 0) return 'Settled';
    if (isOverdue) return 'Overdue';
    if (balance > 0 && isDebtor) return 'Active Debt';
    if (balance < 0 && isCreditor) return 'Active Credit';
    if (balance > 50000) return 'Major Account';
    if (balance > 10000) return 'Medium Account';
    return 'Small Account';
  }

  // Get suggested action for the contact
  String get suggestedAction {
    if (isDebtor) {
      if (balance > 0) {
        if (isOverdue) return 'Send urgent reminder';
        if (daysSinceLastTransaction > 7) return 'Follow up on payment';
        return 'Payment expected soon';
      } else if (balance < 0) {
        return 'Issue refund or credit note';
      }
    } else { // Creditor
      if (balance > 0) {
        return 'Schedule payment';
      } else if (balance < 0) {
        return 'Request credit utilization';
      }
    }
    return 'No action needed';
  }

  // Validate Nigerian phone number
  bool get hasValidPhoneNumber {
    if (phoneNumber == null) return false;
    final regex = RegExp(r'^(0[7-9][0-1]\d{8})$');
    return regex.hasMatch(phoneNumber!.replaceAll(RegExp(r'[^\d]'), ''));
  }

  // Get contact display name with business name if available
  String get displayName {
    if (businessName != null && businessName!.isNotEmpty) {
      return '$name (${businessName!})';
    }
    return name;
  }

  // Get short info summary
  String get infoSummary {
    return '${typeDisplayName} • ${formattedBalanceWithCommas} • $transactionRecency';
  }
}