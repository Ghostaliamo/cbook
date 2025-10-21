// models/business_book.dart
class BusinessBook {
  final String id;
  final String name;
  final String businessType;
  final DateTime createdAt;
  final String currency;
  final List<TeamMember> teamMembers;
  final BookSettings settings;
  final BusinessStats stats;
  final String ownerId; // Critical for security and access control
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isActive;
  final String? description;

  BusinessBook({
    required this.id,
    required this.name,
    required this.businessType,
    required this.createdAt,
    this.currency = 'NGN',
    required this.teamMembers,
    required this.settings,
    required this.stats,
    required this.ownerId, // Required field for security
    this.updatedAt,
    this.updatedBy,
    this.isActive = true,
    this.description,
  });

  // Add copyWith method
  BusinessBook copyWith({
    String? id,
    String? name,
    String? businessType,
    DateTime? createdAt,
    String? currency,
    List<TeamMember>? teamMembers,
    BookSettings? settings,
    BusinessStats? stats,
    String? ownerId,
    DateTime? updatedAt,
    String? updatedBy,
    bool? isActive,
    String? description,
  }) {
    return BusinessBook(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      teamMembers: teamMembers ?? this.teamMembers,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      ownerId: ownerId ?? this.ownerId, // Include ownerId
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'businessType': businessType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'currency': currency,
      'teamMembers': teamMembers.map((member) => member.toMap()).toList(),
      'settings': settings.toMap(),
      'stats': stats.toMap(),
      'ownerId': ownerId, // Include in serialization
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'description': description,
    };
  }

  factory BusinessBook.fromMap(Map<String, dynamic> map) {
    return BusinessBook(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      businessType: map['businessType'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      currency: map['currency'] ?? 'NGN',
      teamMembers: List<TeamMember>.from(
          (map['teamMembers'] ?? []).map((x) => TeamMember.fromMap(x))),
      settings: BookSettings.fromMap(map['settings'] ?? {}),
      stats: BusinessStats.fromMap(map['stats'] ?? {}),
      ownerId: map['ownerId'] ?? '', // Handle missing ownerId
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      updatedBy: map['updatedBy'],
      isActive: map['isActive'] ?? true,
      description: map['description'],
    );
  }

  // Helper methods for business logic
  bool isOwner(String userId) {
    return ownerId == userId;
  }

  bool hasAccess(String userId) {
    return teamMembers.any((member) => 
      member.userId == userId && member.isActive);
  }

  bool hasPermission(String userId, String permission) {
    final member = teamMembers.firstWhere(
      (m) => m.userId == userId && m.isActive,
      orElse: () => TeamMember(
        userId: '',
        role: '',
        permissions: [],
        joinedDate: DateTime.now(),
        isActive: false,
      ),
    );
    
    return member.isActive && member.permissions.contains(permission);
  }

  String? getUserRole(String userId) {
    final member = teamMembers.firstWhere(
      (m) => m.userId == userId && m.isActive,
      orElse: () => TeamMember(
        userId: '',
        role: '',
        permissions: [],
        joinedDate: DateTime.now(),
        isActive: false,
      ),
    );
    
    return member.isActive ? member.role : null;
  }

  // Get active team members
  List<TeamMember> get activeTeamMembers {
    return teamMembers.where((member) => member.isActive).toList();
  }

  // Get inactive team members
  List<TeamMember> get inactiveTeamMembers {
    return teamMembers.where((member) => !member.isActive).toList();
  }

// In your BusinessBook model, add a helper field
List<String> get teamMemberIds {
  return teamMembers
      .where((member) => member.isActive)
      .map((member) => member.userId)
      .toList();
}

// Then store this in Firestore as well, or use it for quick checks
  // Check if book needs attention (low profit margin, etc.)
  bool get needsAttention {
    return stats.profitMargin < 10 || 
           (stats.totalRevenue > 0 && stats.totalExpenses > stats.totalRevenue);
  }

  // Get business health status
  String get healthStatus {
    if (stats.profitMargin > 20) return 'Excellent';
    if (stats.profitMargin > 10) return 'Good';
    if (stats.profitMargin > 0) return 'Fair';
    return 'Needs Attention';
  }
}

class TeamMember {
  final String userId;
  final String role; // owner, partner, staff, accountant, manager
  final List<String> permissions;
  final DateTime joinedDate;
  final bool isActive;
  final DateTime? lastActive;
  final String? email; // Optional: for display purposes
  final String? name; // Optional: for display purposes

  TeamMember({
    required this.userId,
    required this.role,
    required this.permissions,
    required this.joinedDate,
    this.isActive = true,
    this.lastActive,
    this.email,
    this.name,
  });

  // Add copyWith method
  TeamMember copyWith({
    String? userId,
    String? role,
    List<String>? permissions,
    DateTime? joinedDate,
    bool? isActive,
    DateTime? lastActive,
    String? email,
    String? name,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedDate: joinedDate ?? this.joinedDate,
      isActive: isActive ?? this.isActive,
      lastActive: lastActive ?? this.lastActive,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'permissions': permissions,
      'joinedDate': joinedDate.millisecondsSinceEpoch,
      'isActive': isActive,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'email': email,
      'name': name,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      joinedDate: map['joinedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['joinedDate'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      lastActive: map['lastActive'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'])
          : null,
      email: map['email'],
      name: map['name'],
    );
  }

  // Helper methods
  bool get isOwner => role == 'owner';
  bool get canManageUsers => permissions.contains('manage_users');
  bool get canManageSettings => permissions.contains('manage_settings');
  bool get canDelete => permissions.contains('delete');

  // Get tenure in months
  double get tenureInMonths {
    final now = DateTime.now();
    final difference = now.difference(joinedDate);
    return difference.inDays / 30;
  }
}

class BookSettings {
  final bool enableVat;
  final double vatRate;
  final String fiscalYearStart;
  final bool autoBackup;
  final bool multiCurrency;
  final List<String> enabledFeatures;
  final bool requireApproval;
  final double approvalThreshold;
  final bool enableNotifications;
  final String defaultPaymentMethod;
  final List<String> currencyOptions;
  final bool enableTaxReporting;
  final bool enableDebtReminders;

  BookSettings({
    this.enableVat = true,
    this.vatRate = 7.5, // Nigeria VAT rate
    this.fiscalYearStart = 'January',
    this.autoBackup = true,
    this.multiCurrency = false,
    this.enabledFeatures = const ['transactions', 'inventory', 'reports', 'contacts'],
    this.requireApproval = false,
    this.approvalThreshold = 100000, // ₦100,000
    this.enableNotifications = true,
    this.defaultPaymentMethod = 'cash',
    this.currencyOptions = const ['NGN', 'USD', 'EUR', 'GBP'],
    this.enableTaxReporting = true,
    this.enableDebtReminders = true,
  });

  // Add copyWith method
  BookSettings copyWith({
    bool? enableVat,
    double? vatRate,
    String? fiscalYearStart,
    bool? autoBackup,
    bool? multiCurrency,
    List<String>? enabledFeatures,
    bool? requireApproval,
    double? approvalThreshold,
    bool? enableNotifications,
    String? defaultPaymentMethod,
    List<String>? currencyOptions,
    bool? enableTaxReporting,
    bool? enableDebtReminders,
  }) {
    return BookSettings(
      enableVat: enableVat ?? this.enableVat,
      vatRate: vatRate ?? this.vatRate,
      fiscalYearStart: fiscalYearStart ?? this.fiscalYearStart,
      autoBackup: autoBackup ?? this.autoBackup,
      multiCurrency: multiCurrency ?? this.multiCurrency,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      requireApproval: requireApproval ?? this.requireApproval,
      approvalThreshold: approvalThreshold ?? this.approvalThreshold,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      currencyOptions: currencyOptions ?? this.currencyOptions,
      enableTaxReporting: enableTaxReporting ?? this.enableTaxReporting,
      enableDebtReminders: enableDebtReminders ?? this.enableDebtReminders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableVat': enableVat,
      'vatRate': vatRate,
      'fiscalYearStart': fiscalYearStart,
      'autoBackup': autoBackup,
      'multiCurrency': multiCurrency,
      'enabledFeatures': enabledFeatures,
      'requireApproval': requireApproval,
      'approvalThreshold': approvalThreshold,
      'enableNotifications': enableNotifications,
      'defaultPaymentMethod': defaultPaymentMethod,
      'currencyOptions': currencyOptions,
      'enableTaxReporting': enableTaxReporting,
      'enableDebtReminders': enableDebtReminders,
    };
  }

  factory BookSettings.fromMap(Map<String, dynamic> map) {
    return BookSettings(
      enableVat: map['enableVat'] ?? true,
      vatRate: map['vatRate']?.toDouble() ?? 7.5,
      fiscalYearStart: map['fiscalYearStart'] ?? 'January',
      autoBackup: map['autoBackup'] ?? true,
      multiCurrency: map['multiCurrency'] ?? false,
      enabledFeatures: List<String>.from(map['enabledFeatures'] ?? 
          ['transactions', 'inventory', 'reports', 'contacts']),
      requireApproval: map['requireApproval'] ?? false,
      approvalThreshold: map['approvalThreshold']?.toDouble() ?? 100000,
      enableNotifications: map['enableNotifications'] ?? true,
      defaultPaymentMethod: map['defaultPaymentMethod'] ?? 'cash',
      currencyOptions: List<String>.from(map['currencyOptions'] ?? 
          ['NGN', 'USD', 'EUR', 'GBP']),
      enableTaxReporting: map['enableTaxReporting'] ?? true,
      enableDebtReminders: map['enableDebtReminders'] ?? true,
    );
  }

  // Helper methods
  bool get isVatEnabled => enableVat;
  bool get isAutoBackupEnabled => autoBackup;
  bool get isMultiCurrencyEnabled => multiCurrency;
  bool get isNotificationEnabled => enableNotifications;

  // Check if feature is enabled
  bool isFeatureEnabled(String feature) {
    return enabledFeatures.contains(feature);
  }

  // Get Nigerian-specific settings
  Map<String, dynamic> get nigerianSettings {
    return {
      'vatRate': vatRate,
      'vatEnabled': enableVat,
      'defaultCurrency': 'NGN',
      'taxReporting': enableTaxReporting,
    };
  }
}

class BusinessStats {
  final double totalRevenue;
  final double totalExpenses;
  final int activeCustomers;
  final int activeSuppliers;
  final double profitMargin;
  final DateTime lastUpdated;
  final double totalAssets;
  final double totalLiabilities;
  final double cashFlow;
  final int totalTransactions;
  final double averageTransactionValue;
  final double customerRetentionRate;

  BusinessStats({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.activeCustomers,
    required this.activeSuppliers,
    required this.profitMargin,
    required this.lastUpdated,
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.cashFlow = 0,
    this.totalTransactions = 0,
    this.averageTransactionValue = 0,
    this.customerRetentionRate = 0,
  });

  // Add copyWith method
  BusinessStats copyWith({
    double? totalRevenue,
    double? totalExpenses,
    int? activeCustomers,
    int? activeSuppliers,
    double? profitMargin,
    DateTime? lastUpdated,
    double? totalAssets,
    double? totalLiabilities,
    double? cashFlow,
    int? totalTransactions,
    double? averageTransactionValue,
    double? customerRetentionRate,
  }) {
    return BusinessStats(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      activeSuppliers: activeSuppliers ?? this.activeSuppliers,
      profitMargin: profitMargin ?? this.profitMargin,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalAssets: totalAssets ?? this.totalAssets,
      totalLiabilities: totalLiabilities ?? this.totalLiabilities,
      cashFlow: cashFlow ?? this.cashFlow,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      averageTransactionValue: averageTransactionValue ?? this.averageTransactionValue,
      customerRetentionRate: customerRetentionRate ?? this.customerRetentionRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'activeCustomers': activeCustomers,
      'activeSuppliers': activeSuppliers,
      'profitMargin': profitMargin,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'totalAssets': totalAssets,
      'totalLiabilities': totalLiabilities,
      'cashFlow': cashFlow,
      'totalTransactions': totalTransactions,
      'averageTransactionValue': averageTransactionValue,
      'customerRetentionRate': customerRetentionRate,
    };
  }

  factory BusinessStats.fromMap(Map<String, dynamic> map) {
    return BusinessStats(
      totalRevenue: map['totalRevenue']?.toDouble() ?? 0,
      totalExpenses: map['totalExpenses']?.toDouble() ?? 0,
      activeCustomers: map['activeCustomers'] ?? 0,
      activeSuppliers: map['activeSuppliers'] ?? 0,
      profitMargin: map['profitMargin']?.toDouble() ?? 0,
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : DateTime.now(),
      totalAssets: map['totalAssets']?.toDouble() ?? 0,
      totalLiabilities: map['totalLiabilities']?.toDouble() ?? 0,
      cashFlow: map['cashFlow']?.toDouble() ?? 0,
      totalTransactions: map['totalTransactions'] ?? 0,
      averageTransactionValue: map['averageTransactionValue']?.toDouble() ?? 0,
      customerRetentionRate: map['customerRetentionRate']?.toDouble() ?? 0,
    );
  }

  // Helper methods for business insights
  double get netProfit => totalRevenue - totalExpenses;
  double get netWorth => totalAssets - totalLiabilities;
  double get currentRatio => totalAssets > 0 ? totalLiabilities / totalAssets : 0;
  
  // Get growth metrics
  double get revenueGrowth {
    if (totalRevenue == 0) return 0;
    return (netProfit / totalRevenue) * 100;
  }

  // Check financial health
  String get financialHealth {
    if (profitMargin > 20 && currentRatio < 0.5) return 'Excellent';
    if (profitMargin > 10 && currentRatio < 0.7) return 'Good';
    if (profitMargin > 0 && currentRatio < 1.0) return 'Fair';
    return 'Needs Attention';
  }

  // Get Nigerian business insights
  Map<String, dynamic> get nigerianBusinessInsights {
    return {
      'vatObligation': totalRevenue * 0.075, // 7.5% VAT
      'profitability': profitMargin > 15 ? 'High' : profitMargin > 5 ? 'Medium' : 'Low',
      'customerBaseHealth': activeCustomers > 50 ? 'Strong' : activeCustomers > 20 ? 'Moderate' : 'Developing',
      'supplierRelations': activeSuppliers > 10 ? 'Diverse' : activeSuppliers > 5 ? 'Adequate' : 'Limited',
    };
  }

  // Check if stats need update (older than 24 hours)
  bool get needsUpdate {
    return DateTime.now().difference(lastUpdated).inHours > 24;
  }

  // Get performance summary
  Map<String, String> get performanceSummary {
    return {
      'profitMargin': '${profitMargin.toStringAsFixed(1)}%',
      'netProfit': '₦${netProfit.toStringAsFixed(2)}',
      'revenue': '₦${totalRevenue.toStringAsFixed(2)}',
      'expenses': '₦${totalExpenses.toStringAsFixed(2)}',
      'customers': activeCustomers.toString(),
      'suppliers': activeSuppliers.toString(),
    };
  }
}

// Additional helper classes for business operations
class BusinessBookSummary {
  final String bookId;
  final String bookName;
  final double totalRevenue;
  final double totalExpenses;
  final double profitMargin;
  final int transactionCount;
  final DateTime lastUpdated;

  BusinessBookSummary({
    required this.bookId,
    required this.bookName,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.profitMargin,
    required this.transactionCount,
    required this.lastUpdated,
  });

  double get netProfit => totalRevenue - totalExpenses;
}

// Enum for business types (common Nigerian business types)
enum NigerianBusinessType {
  retail('Retail'),
  wholesale('Wholesale'),
  manufacturing('Manufacturing'),
  service('Service'),
  construction('Construction'),
  agriculture('Agriculture'),
  transportation('Transportation'),
  hospitality('Hospitality'),
  technology('Technology'),
  healthcare('Healthcare'),
  education('Education'),
  fashion('Fashion'),
  foodBeverage('Food & Beverage'),
  realEstate('Real Estate'),
  consulting('Consulting');

  final String displayName;
  const NigerianBusinessType(this.displayName);
}

// Extension for Nigerian business types
extension NigerianBusinessTypeExtension on NigerianBusinessType {
  String get code {
    switch (this) {
      case NigerianBusinessType.retail:
        return 'retail';
      case NigerianBusinessType.wholesale:
        return 'wholesale';
      case NigerianBusinessType.manufacturing:
        return 'manufacturing';
      case NigerianBusinessType.service:
        return 'service';
      case NigerianBusinessType.construction:
        return 'construction';
      case NigerianBusinessType.agriculture:
        return 'agriculture';
      case NigerianBusinessType.transportation:
        return 'transportation';
      case NigerianBusinessType.hospitality:
        return 'hospitality';
      case NigerianBusinessType.technology:
        return 'technology';
      case NigerianBusinessType.healthcare:
        return 'healthcare';
      case NigerianBusinessType.education:
        return 'education';
      case NigerianBusinessType.fashion:
        return 'fashion';
      case NigerianBusinessType.foodBeverage:
        return 'food_beverage';
      case NigerianBusinessType.realEstate:
        return 'real_estate';
      case NigerianBusinessType.consulting:
        return 'consulting';
    }
  }

  // Get default settings for each business type
  BookSettings get defaultSettings {
    switch (this) {
      case NigerianBusinessType.retail:
      case NigerianBusinessType.wholesale:
        return BookSettings(
          enableVat: true,
          vatRate: 7.5,
          enabledFeatures: ['transactions', 'inventory', 'reports', 'contacts', 'sales'],
        );
      case NigerianBusinessType.manufacturing:
        return BookSettings(
          enableVat: true,
          vatRate: 7.5,
          enabledFeatures: ['transactions', 'inventory', 'reports', 'contacts', 'production'],
        );
      case NigerianBusinessType.service:
      case NigerianBusinessType.consulting:
        return BookSettings(
          enableVat: true,
          vatRate: 7.5,
          enabledFeatures: ['transactions', 'reports', 'contacts', 'invoicing'],
        );
      case NigerianBusinessType.construction:
        return BookSettings(
          enableVat: true,
          vatRate: 7.5,
          enabledFeatures: ['transactions', 'reports', 'contacts', 'projects'],
        );
      default:
        return BookSettings();
    }
  }
}