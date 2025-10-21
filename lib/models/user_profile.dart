// models/user_profile.dart
class UserProfile {
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? profileImage;
  final String? bio;
  final Map<String, dynamic> preferences;
  final DateTime lastLogin;
  final List<String> businessRoles;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.address,
    this.profileImage,
    this.bio,
    required this.preferences,
    required this.lastLogin,
    required this.businessRoles,
    required this.createdAt,
  });

  // Convert UserProfile to Map for Firebase/Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImage': profileImage,
      'bio': bio,
      'preferences': preferences,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
      'businessRoles': businessRoles,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create UserProfile from Map (for Firebase/Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      profileImage: map['profileImage'],
      bio: map['bio'],
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin'])
          : DateTime.now(),
      businessRoles: List<String>.from(map['businessRoles'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Helper method to create a copy with updated fields
  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? profileImage,
    String? bio,
    Map<String, dynamic>? preferences,
    DateTime? lastLogin,
    List<String>? businessRoles,
    DateTime? createdAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      lastLogin: lastLogin ?? this.lastLogin,
      businessRoles: businessRoles ?? this.businessRoles,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Update last login time
  UserProfile withLastLoginUpdate() {
    return copyWith(lastLogin: DateTime.now());
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'UserProfile{userId: $userId, fullName: $fullName, email: $email, phone: $phoneNumber}';
  }

  // Override equality for comparing user profiles
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  // Helper methods for common operations
  bool get hasCompleteProfile => 
      fullName.isNotEmpty && 
      email != null && email!.isNotEmpty &&
      phoneNumber != null && phoneNumber!.isNotEmpty;

  String get displayName => fullName.isNotEmpty ? fullName : (email ?? 'User');

  String get initials {
    if (fullName.isNotEmpty) {
      final names = fullName.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return fullName.substring(0, 2).toUpperCase();
    }
    return email != null && email!.isNotEmpty 
        ? email!.substring(0, 2).toUpperCase()
        : 'US';
  }

  // Check if user has a specific business role
  bool hasRole(String role) => businessRoles.contains(role);

  // Check if user is an owner in any business
  bool get isBusinessOwner => hasRole('owner');

  // Check if user is a manager
  bool get isManager => hasRole('manager') || hasRole('owner');

  // Get user's primary role (highest permission level)
  String get primaryRole {
    if (hasRole('owner')) return 'Owner';
    if (hasRole('partner')) return 'Partner';
    if (hasRole('manager')) return 'Manager';
    if (hasRole('accountant')) return 'Accountant';
    if (hasRole('staff')) return 'Staff';
    return 'User';
  }

  // Get formatted last login date
  String get formattedLastLogin {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${lastLogin.day}/${lastLogin.month}/${lastYear}';
  }

  int get lastYear => lastLogin.year;

  // Get account age in days
  int get accountAgeInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Check if user is new (less than 7 days old)
  bool get isNewUser => accountAgeInDays < 7;

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

  // Check if profile has a photo
  bool get hasProfilePhoto => profileImage != null && profileImage!.isNotEmpty;

  // Get default preferences if none exist
  static Map<String, dynamic> get defaultPreferences {
    return {
      'language': 'en',
      'currency': 'NGN',
      'theme': 'light',
      'notifications': true,
      'autoBackup': true,
      'vatEnabled': true,
      'vatRate': 7.5,
      'receiptPrinting': false,
      'smsAlerts': false,
      'emailReports': true,
    };
  }

  // Get a preference value with fallback to default
  dynamic getPreference(String key) {
    return preferences[key] ?? defaultPreferences[key];
  }

  // Update a preference
  UserProfile withPreference(String key, dynamic value) {
    final newPreferences = Map<String, dynamic>.from(preferences);
    newPreferences[key] = value;
    return copyWith(preferences: newPreferences);
  }

  // Add a business role
  UserProfile withRole(String role) {
    final newRoles = List<String>.from(businessRoles);
    if (!newRoles.contains(role)) {
      newRoles.add(role);
    }
    return copyWith(businessRoles: newRoles);
  }

  // Remove a business role
  UserProfile withoutRole(String role) {
    final newRoles = List<String>.from(businessRoles);
    newRoles.remove(role);
    return copyWith(businessRoles: newRoles);
  }

  // Check if user can perform an action based on roles
  bool canPerform(String action) {
    // Simple permission check based on roles
    final userRoles = businessRoles;
    
    if (userRoles.contains('owner')) return true;
    if (userRoles.contains('partner') && 
        ['view', 'edit', 'create', 'delete'].contains(action)) return true;
    if (userRoles.contains('manager') && 
        ['view', 'edit', 'create'].contains(action)) return true;
    if (userRoles.contains('accountant') && 
        ['view', 'edit'].contains(action) && 
        action.contains('financial')) return true;
    if (userRoles.contains('staff') && 
        ['view'].contains(action)) return true;
    
    return false;
  }
}