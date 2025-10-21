// providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cbook/models/user.dart' as local;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  local.User? _currentUser;
  bool _isLoading = false;
  List<local.User> _users = []; // In-memory storage
  final String _usersKey = 'cached_users'; // Key for SharedPreferences

  local.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load users from persistent storage first
      await _loadUsers();
      
      // Check Firebase authentication
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await syncWithFirebaseUser(firebaseUser);
        print('Loaded Firebase user: ${_currentUser?.email}');
      } else {
        print('No Firebase user found');
      }
    } catch (e) {
      print('Error initializing auth provider: $e');
    }
    notifyListeners();
  }

  // Load users from SharedPreferences
  Future<void> _loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        _users = usersList.map((userMap) => local.User.fromJson(userMap)).toList();
        print('Loaded ${_users.length} users from persistent storage');
      }
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  // Save users to SharedPreferences
  Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = json.encode(_users.map((user) => user.toJson()).toList());
      await prefs.setString(_usersKey, usersJson);
      print('Saved ${_users.length} users to persistent storage');
    } catch (e) {
      print('Error saving users: $e');
    }
  }

  Future<void> syncWithFirebaseUser(User firebaseUser) async {
    try {
      final localUser = _getUserById(firebaseUser.uid);
      
      if (localUser == null) {
        final newUser = local.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          businessName: firebaseUser.displayName ?? 'My Business',
          phoneNumber: firebaseUser.phoneNumber,
          createdAt: DateTime.now(),
          isFirebaseUser: true,
        );
        
        _users.add(newUser);
        _currentUser = newUser;
        await _saveUsers(); // Save to persistent storage
        print('Created new user from Firebase: ${newUser.email}');
      } else {
        final updatedUser = localUser.copyWith(
          email: firebaseUser.email ?? localUser.email,
          phoneNumber: firebaseUser.phoneNumber ?? localUser.phoneNumber,
          isFirebaseUser: true,
        );
        
        _users.removeWhere((user) => user.id == updatedUser.id);
        _users.add(updatedUser);
        _currentUser = updatedUser;
        await _saveUsers(); // Save to persistent storage
        print('Updated user from Firebase: ${updatedUser.email}');
      }
      
      notifyListeners();
    } catch (e) {
      print('Error syncing with Firebase user: $e');
      rethrow;
    }
  }

  local.User? _getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> register(String email, String password, String businessName, {String? phoneNumber}) async {
    _isLoading = true;
    notifyListeners();

    try {
      try {
        final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          // Update display name for Firebase user
          await firebaseUser.updateDisplayName(businessName);
          
          final newUser = local.User(
            id: firebaseUser.uid,
            email: email,
            phoneNumber: phoneNumber,
            businessName: businessName,
            createdAt: DateTime.now(),
            isFirebaseUser: true,
          );

          _users.add(newUser);
          _currentUser = newUser;
          await _saveUsers(); // Save to persistent storage
          print('User registered with Firebase: ${newUser.email}');
          return;
        }
      } catch (firebaseError) {
        print('Firebase registration failed: $firebaseError');
        // Continue with local registration if Firebase fails
      }

      if (_users.any((user) => user.email == email)) {
        throw Exception('User with this email already exists');
      }

      final newUser = local.User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        phoneNumber: phoneNumber,
        businessName: businessName,
        createdAt: DateTime.now(),
        isFirebaseUser: false,
      );

      _users.add(newUser);
      _currentUser = newUser;
      await _saveUsers(); // Save to persistent storage
      print('User registered locally: ${newUser.email}');
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      try {
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final firebaseUser = userCredential.user;
        if (firebaseUser != null) {
          await syncWithFirebaseUser(firebaseUser);
          return;
        }
      } catch (firebaseError) {
        print('Firebase login failed: $firebaseError');
        // Continue with local login if Firebase fails
      }

      final user = _users.firstWhere(
        (user) => user.email == email,
        orElse: () => throw Exception('User not found'),
      );

      _currentUser = user;
      print('User logged in locally: ${user.email}');
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the updateProfile method to save changes
  Future<void> updateProfile({
    String? businessName,
    String? phoneNumber,
    String? email,
  }) async {
    if (_currentUser == null) return;

    try {
      if (_currentUser!.isFirebaseUser) {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          if (businessName != null) {
            await firebaseUser.updateDisplayName(businessName);
          }
          if (email != null && email != _currentUser!.email) {
            await firebaseUser.verifyBeforeUpdateEmail(email);
          }
        }
      }

      final updatedUser = _currentUser!.copyWith(
        businessName: businessName ?? _currentUser!.businessName,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        email: email ?? _currentUser!.email,
      );

      _users.removeWhere((user) => user.id == updatedUser.id);
      _users.add(updatedUser);
      _currentUser = updatedUser;
      await _saveUsers(); // Save to persistent storage
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Update the deleteAccount method to remove from storage
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;

    try {
      if (_currentUser!.isFirebaseUser) {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.delete();
        }
      }

      _users.removeWhere((user) => user.id == _currentUser!.id);
      _currentUser = null;
      await _saveUsers(); // Save to persistent storage
      notifyListeners();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Update the updateUser method to save changes
  Future<void> updateUser(local.User updatedUser) async {
    try {
      _users.removeWhere((user) => user.id == updatedUser.id);
      _users.add(updatedUser);
      _currentUser = updatedUser;
      await _saveUsers(); // Save to persistent storage
      notifyListeners();
      print('User updated successfully: ${updatedUser.email}');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // The rest of your methods remain the same...
  Future<void> logout() async {
    try {
      if (_currentUser?.isFirebaseUser == true) {
        await _firebaseAuth.signOut();
      }
      
      _currentUser = null;
      print('User logged out');
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentUser?.isFirebaseUser != true) {
      throw Exception('Password change only available for Firebase users');
    }

    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePassword(newPassword);
      }
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw Exception('Failed to send password reset email. Please check if this email is registered with Firebase.');
    }
  }

  Future<void> updateCloudSyncPreference(bool enableSync) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        hasCloudSync: enableSync,
      );

      _users.removeWhere((user) => user.id == updatedUser.id);
      _users.add(updatedUser);
      _currentUser = updatedUser;
      await _saveUsers(); // Save to persistent storage
      notifyListeners();
    }
  }

  bool get hasFirebaseAuth => _currentUser?.isFirebaseUser == true;
  String? get firebaseUserId => _currentUser?.isFirebaseUser == true ? _currentUser!.id : null;

  Future<bool> isFirebaseAuthenticated() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      return firebaseUser != null && _currentUser?.id == firebaseUser.uid;
    } catch (e) {
      return false;
    }
  }

  String get authProvider {
    if (_currentUser?.isFirebaseUser == true) {
      return 'firebase';
    }
    return 'local';
  }
}