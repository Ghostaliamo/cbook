// models/user.dart
class User {
  final String id;
  final String email;
  final String? phoneNumber;
  final String businessName;
  final DateTime createdAt;
  final bool hasCloudSync;
  final bool isFirebaseUser;
  final bool isSubscribed;
  final DateTime? subscriptionEndDate;
  final String? subscriptionPlan;

  User({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.businessName,
    required this.createdAt,
    this.hasCloudSync = false,
    this.isFirebaseUser = false,
    this.isSubscribed = false,
    this.subscriptionEndDate,
    this.subscriptionPlan,
  });

  // Copy with method for immutable updates
  User copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? businessName,
    DateTime? createdAt,
    bool? hasCloudSync,
    bool? isFirebaseUser,
    bool? isSubscribed,
    DateTime? subscriptionEndDate,
    String? subscriptionPlan,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessName: businessName ?? this.businessName,
      createdAt: createdAt ?? this.createdAt,
      hasCloudSync: hasCloudSync ?? this.hasCloudSync,
      isFirebaseUser: isFirebaseUser ?? this.isFirebaseUser,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }

  // Add toMap and fromMap methods for Firebase integration
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'businessName': businessName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'hasCloudSync': hasCloudSync,
      'isFirebaseUser': isFirebaseUser,
      'isSubscribed': isSubscribed,
      'subscriptionEndDate': subscriptionEndDate?.millisecondsSinceEpoch,
      'subscriptionPlan': subscriptionPlan,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      businessName: map['businessName'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      hasCloudSync: map['hasCloudSync'] ?? false,
      isFirebaseUser: map['isFirebaseUser'] ?? false,
      isSubscribed: map['isSubscribed'] ?? false,
      subscriptionEndDate: map['subscriptionEndDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['subscriptionEndDate'])
          : null,
      subscriptionPlan: map['subscriptionPlan'],
    );
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'User{id: $id, email: $email, businessName: $businessName, isFirebaseUser: $isFirebaseUser, isSubscribed: $isSubscribed}';
  }

  // Override equality for comparing users
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper method to check if user can use cloud features
  bool get canUseCloudSync => isFirebaseUser && hasCloudSync;

  // Helper method to get display name
  String get displayName => businessName.isNotEmpty ? businessName : email;

  // Helper method to get initials for avatar
  String get initials {
    if (businessName.isNotEmpty) {
      final words = businessName.split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      }
      return businessName.substring(0, 2).toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }

  // Check if user profile is complete
  bool get isProfileComplete =>
      email.isNotEmpty && businessName.isNotEmpty && phoneNumber != null && phoneNumber!.isNotEmpty;

  // Get user creation date in formatted string
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Get user age in days
  int get accountAgeInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Check if user is new (less than 7 days old)
  bool get isNewUser => accountAgeInDays < 7;

  // Check if subscription is active
  bool get isSubscriptionActive {
    if (!isSubscribed) return false;
    if (subscriptionEndDate == null) return false;
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  // Get days until subscription expires
  int get daysUntilSubscriptionExpires {
    if (!isSubscriptionActive) return 0;
    return subscriptionEndDate!.difference(DateTime.now()).inDays;
  }

Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'businessName': businessName,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
    'isFirebaseUser': isFirebaseUser,
    'hasCloudSync': hasCloudSync,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      businessName: json['businessName'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      isFirebaseUser: json['isFirebaseUser'],
      hasCloudSync: json['hasCloudSync'] ?? false,
    );
  }
}