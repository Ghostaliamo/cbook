// providers/business_book_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cbook/models/business_book.dart';
import 'package:cbook/models/user_profile.dart';
import 'package:cbook/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BusinessBookProvider with ChangeNotifier {
  final List<BusinessBook> _businessBooks = [];
  final List<UserProfile> _userProfiles = [];
  
  BusinessBook? _currentBook;
  UserProfile? _currentUserProfile;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isLoading = false;
  bool _isCloudConnected = true;
  String? _lastError;

  BusinessBookProvider() {
    _initialize();
    _setupConnectivityListener();
  }

  BusinessBook? get currentBook => _currentBook;
  UserProfile? get currentUserProfile => _currentUserProfile;
  List<BusinessBook> get allBooks => _businessBooks;
  bool get isLoading => _isLoading;
  bool get isCloudConnected => _isCloudConnected;
  String? get lastError => _lastError;

  Future<void> _initialize() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await loadBusinessBooks();
        await loadUserProfile(user.uid);
      }
    } catch (e) {
      print('BusinessBookProvider initialization error: $e');
      _lastError = 'Initialization failed: $e';
    }
  }

  Future<void> _setupConnectivityListener() async {
    _connectivity.onConnectivityChanged.listen((result) async {
      final wasConnected = _isCloudConnected;
      _isCloudConnected = result != ConnectivityResult.none;
      
      if (!wasConnected && _isCloudConnected) {
        // Reconnected to internet, sync data
        print('Reconnected to internet, syncing data...');
        await _syncAllData();
      }
      
      notifyListeners();
    });
  }

  Future<void> _syncAllData() async {
    try {
      if (_auth.currentUser != null) {
        await loadBusinessBooks();
        await loadUserProfile(_auth.currentUser!.uid);
      }
    } catch (e) {
      print('Data sync error: $e');
    }
  }

  Future<void> createBusinessBook(String name, String businessType, String userId) async {
    print('Creating business book: $name, type: $businessType, user: $userId');
    
    _setLoading(true);
    _lastError = null;
    
    try {
      final newBook = BusinessBook(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        businessType: businessType,
        createdAt: DateTime.now(),
        currency: 'NGN',
        teamMembers: [
          TeamMember(
            userId: userId,
            role: 'owner',
            permissions: _getPermissionsForRole('owner'),
            joinedDate: DateTime.now(),
            isActive: true,
          ),
        ],
        settings: BookSettings(),
        stats: BusinessStats(
          totalRevenue: 0,
          totalExpenses: 0,
          activeCustomers: 0,
          activeSuppliers: 0,
          profitMargin: 0,
          lastUpdated: DateTime.now(),
        ),
        ownerId: userId, // Add ownerId for security
      );

      if (_isCloudConnected) {
        // Save to Firestore if connected
        await _firebaseService.createBusinessBookInCloud(newBook);
        print('Book saved to cloud: ${newBook.id}');
      }

      // Always add to local state
      _businessBooks.add(newBook);
      _currentBook = newBook;
      
      notifyListeners();
      print('Book created successfully: ${newBook.id}');
      
    } catch (e) {
      _lastError = 'Error creating business book: $e';
      print('Error creating business book: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBusinessBooks() async {
    _setLoading(true);
    _lastError = null;
    
    try {
      List<BusinessBook> books;
      
      if (_isCloudConnected) {
        // Load from Firestore if connected
        books = await _firebaseService.fetchBusinessBooksFromCloud();
        print('Loaded ${books.length} business books from cloud');
      } else {
        // Use local data if offline
        books = _businessBooks;
        print('Using local business books (offline mode)');
      }
      
      _businessBooks.clear();
      _businessBooks.addAll(books);
      
      if (_businessBooks.isNotEmpty && _currentBook == null) {
        _currentBook = _businessBooks.first;
      }
      
      notifyListeners();
      print('Total business books: ${_businessBooks.length}');
      
    } catch (e) {
      _lastError = 'Error loading business books: $e';
      print('Error loading business books: $e');
      
      // If cloud load fails but we have local data, use it
      if (_businessBooks.isNotEmpty) {
        print('Using existing local data due to cloud error');
        notifyListeners();
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> switchBook(String bookId) async {
    print('Switching to book ID: $bookId');
    
    try {
      final book = _businessBooks.firstWhere((book) => book.id == bookId);
      _currentBook = book;
      notifyListeners();
      print('Current book switched to: ${_currentBook?.name}');
    } catch (e) {
      _lastError = 'Book not found with ID: $bookId';
      print('Book not found with ID: $bookId');
      throw Exception('Book not found');
    }
  }

  // Update these methods in your BusinessBookProvider class

void addTeamMember(String email, String role, List<String> permissions, DateTime joinedDate, {String? name}) {
  if (currentBook == null) return;
  
  final newMember = TeamMember(
    userId: email, // Using email as user ID for now
    role: role,
    permissions: permissions,
    joinedDate: joinedDate,
    email: email,
    name: name,
  );
  
  currentBook!.teamMembers.add(newMember);
  notifyListeners();
  // Save to database or backend here
}

void updateTeamMemberRole(String userId, String newRole, List<String> newPermissions) {
  if (currentBook == null) return;
  
  final index = currentBook!.teamMembers.indexWhere((member) => member.userId == userId);
  if (index != -1) {
    final existingMember = currentBook!.teamMembers[index];
    currentBook!.teamMembers[index] = TeamMember(
      userId: existingMember.userId,
      role: newRole,
      permissions: newPermissions,
      joinedDate: existingMember.joinedDate,
      isActive: existingMember.isActive,
      lastActive: existingMember.lastActive,
      email: existingMember.email,
      name: existingMember.name,
    );
    notifyListeners();
    // Save to database or backend here
  }
}

void removeTeamMember(String userId) {
  if (currentBook == null) return;
  
  currentBook!.teamMembers.removeWhere((member) => member.userId == userId);
  notifyListeners();
  // Save to database or backend here
}

  Future<void> updateBookSettings(BookSettings newSettings) async {
    if (_currentBook == null) {
      _lastError = 'Cannot update settings: no current book';
      print('Cannot update settings: no current book');
      throw Exception('No current book selected');
    }

    print('Updating book settings');
    
    _setLoading(true);
    
    try {
      final updatedBook = _currentBook!.copyWith(settings: newSettings);
      
      if (_isCloudConnected) {
        // Update in Firestore if connected
        await _firebaseService.updateBusinessBookInCloud(updatedBook);
      }
      
      // Update local storage
      final index = _businessBooks.indexWhere((book) => book.id == updatedBook.id);
      if (index != -1) {
        _businessBooks[index] = updatedBook;
      }
      
      _currentBook = updatedBook;
      notifyListeners();
      print('Book settings updated successfully');
      
    } catch (e) {
      _lastError = 'Error updating book settings: $e';
      print('Error updating book settings: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    print('Updating user profile: ${profile.userId}');
    
    _setLoading(true);
    _lastError = null;
    
    try {
      if (_isCloudConnected) {
        // Update in Firestore if connected
        await _firebaseService.updateUserProfileInCloud(profile);
      }
      
      // Update local storage
      final index = _userProfiles.indexWhere((p) => p.userId == profile.userId);
      if (index != -1) {
        _userProfiles[index] = profile;
      } else {
        _userProfiles.add(profile);
      }
      
      _currentUserProfile = profile;
      notifyListeners();
      print('User profile updated successfully');
      
    } catch (e) {
      _lastError = 'Error updating user profile: $e';
      print('Error updating user profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProfile(String userId) async {
    print('Loading user profile: $userId');
    
    _setLoading(true);
    _lastError = null;
    
    try {
      UserProfile? profile;
      
      if (_isCloudConnected) {
        // Load from Firestore if connected
        profile = await _firebaseService.fetchUserProfileFromCloud(userId);
      }
      
      if (profile != null) {
        _currentUserProfile = profile;
        print('User profile loaded: ${profile.fullName}');
      } else {
        // Create a default profile if none exists
        _currentUserProfile = UserProfile(
          userId: userId,
          fullName: _auth.currentUser?.displayName ?? 'User $userId',
          email: _auth.currentUser?.email,
          phoneNumber: null,
          address: null,
          profileImage: _auth.currentUser?.photoURL,
          bio: null,
          preferences: UserProfile.defaultPreferences,
          lastLogin: DateTime.now(),
          businessRoles: [],
          createdAt: DateTime.now(),
        );
        print('Created default user profile');
        
        if (_isCloudConnected) {
          // Save the new profile to Firestore if connected
          await _firebaseService.updateUserProfileInCloud(_currentUserProfile!);
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      _lastError = 'Error loading user profile: $e';
      print('Error loading user profile: $e');
      
      // Create a minimal profile if loading fails
      if (_currentUserProfile == null) {
        _currentUserProfile = UserProfile(
          userId: userId,
          fullName: 'User $userId',
          email: _auth.currentUser?.email,
          phoneNumber: null,
          address: null,
          profileImage: null,
          bio: null,
          preferences: UserProfile.defaultPreferences,
          lastLogin: DateTime.now(),
          businessRoles: [],
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  List<String> _getPermissionsForRole(String role) {
    switch (role) {
      case 'owner':
        return ['read', 'write', 'delete', 'manage_users', 'manage_settings'];
      case 'partner':
        return ['read', 'write', 'manage_users'];
      case 'manager':
        return ['read', 'write', 'manage_inventory'];
      case 'accountant':
        return ['read', 'write', 'manage_finances'];
      case 'staff':
        return ['read', 'write'];
      default:
        return ['read'];
    }
  }

  bool hasPermission(String permission) {
    if (_currentBook == null || _currentUserProfile == null) {
      print('Permission check failed: no current book or user profile');
      return false;
    }
    
    final member = _currentBook!.teamMembers.firstWhere(
      (m) => m.userId == _currentUserProfile!.userId,
      orElse: () => TeamMember(
        userId: '',
        role: '',
        permissions: [],
        joinedDate: DateTime.now(),
        isActive: false,
      ),
    );

    final hasPerm = member.permissions.contains(permission);
    print('Permission check for $permission: $hasPerm (user: ${_currentUserProfile!.userId})');
    return hasPerm;
  }

  Future<void> updateBusinessStats({
    double? revenue,
    double? expenses,
    int? customers,
    int? suppliers,
  }) async {
    if (_currentBook == null) {
      _lastError = 'Cannot update stats: no current book';
      print('Cannot update stats: no current book');
      throw Exception('No current book selected');
    }

    print('Updating business stats');
    
    _setLoading(true);
    
    try {
      final totalRevenue = revenue ?? _currentBook!.stats.totalRevenue;
      final totalExpenses = expenses ?? _currentBook!.stats.totalExpenses;
      
      double profitMargin = 0;
      if (totalRevenue > 0) {
        profitMargin = ((totalRevenue - totalExpenses) / totalRevenue) * 100;
      }

      final newStats = BusinessStats(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        activeCustomers: customers ?? _currentBook!.stats.activeCustomers,
        activeSuppliers: suppliers ?? _currentBook!.stats.activeSuppliers,
        profitMargin: profitMargin,
        lastUpdated: DateTime.now(),
      );

      final updatedBook = _currentBook!.copyWith(stats: newStats);
      
      if (_isCloudConnected) {
        // Update in Firestore if connected
        await _firebaseService.updateBusinessBookInCloud(updatedBook);
      }
      
      // Update local storage
      final index = _businessBooks.indexWhere((book) => book.id == updatedBook.id);
      if (index != -1) {
        _businessBooks[index] = updatedBook;
      }
      
      _currentBook = updatedBook;
      notifyListeners();
      print('Business stats updated successfully');
      
    } catch (e) {
      _lastError = 'Error updating business stats: $e';
      print('Error updating business stats: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBook(BusinessBook updatedBook) async {
    print('Updating book: ${updatedBook.id}');
    
    _setLoading(true);
    _lastError = null;
    
    try {
      if (_isCloudConnected) {
        // Update in Firestore if connected
        await _firebaseService.updateBusinessBookInCloud(updatedBook);
      }
      
      // Update local storage
      final index = _businessBooks.indexWhere((book) => book.id == updatedBook.id);
      if (index != -1) {
        _businessBooks[index] = updatedBook;
        
        // If this is the current book, update it too
        if (_currentBook?.id == updatedBook.id) {
          _currentBook = updatedBook;
        }
        
        notifyListeners();
        print('Book updated successfully: ${updatedBook.name}');
      } else {
        _lastError = 'Book not found with ID: ${updatedBook.id}';
        print('Book not found with ID: ${updatedBook.id}');
        throw Exception('Book not found');
      }
    } catch (e) {
      _lastError = 'Error updating book: $e';
      print('Error updating book: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get book by ID
  BusinessBook? getBookById(String bookId) {
    try {
      return _businessBooks.firstWhere((book) => book.id == bookId);
    } catch (e) {
      print('Book not found with ID: $bookId');
      return null;
    }
  }

  // Check if user has access to a book
  bool hasAccessToBook(String bookId, String userId) {
    final book = getBookById(bookId);
    if (book == null) return false;
    
    return book.teamMembers.any((member) => member.userId == userId && member.isActive);
  }

  // Get user's role in current book
  String? getCurrentUserRole() {
    if (_currentBook == null || _currentUserProfile == null) {
      return null;
    }
    
    final member = _currentBook!.teamMembers.firstWhere(
      (m) => m.userId == _currentUserProfile!.userId,
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

  // Clear current book (useful for logout)
  void clearCurrentBook() {
    _currentBook = null;
    notifyListeners();
    print('Current book cleared');
  }

  // Clear all data (useful for logout)
  Future<void> clearAllData() async {
    _businessBooks.clear();
    _userProfiles.clear();
    _currentBook = null;
    _currentUserProfile = null;
    _lastError = null;
    notifyListeners();
    print('All business book data cleared');
  }

  // Sync all local changes to cloud when connectivity is restored
  Future<void> syncPendingChanges() async {
    if (!_isCloudConnected) {
      print('Cannot sync: no internet connection');
      return;
    }

    _setLoading(true);
    print('Syncing pending changes to cloud...');
    
    try {
      // Sync user profile
      if (_currentUserProfile != null) {
        await _firebaseService.updateUserProfileInCloud(_currentUserProfile!);
      }
      
      // Sync business books
      for (final book in _businessBooks) {
        await _firebaseService.updateBusinessBookInCloud(book);
      }
      
      print('All pending changes synced successfully');
      
    } catch (e) {
      _lastError = 'Error syncing changes: $e';
      print('Error syncing changes: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _lastError = null; // Clear error when starting new operation
    }
    notifyListeners();
  }

  // In BusinessBookProvider - update the deleteBook method
Future<void> deleteBook(String bookId) async {
  _setLoading(true);
  _lastError = null;
  
  try {
    // Remove from local storage
    _businessBooks.removeWhere((book) => book.id == bookId);
    
    // Update current book if it's the one being deleted
    if (_currentBook?.id == bookId) {
      _currentBook = _businessBooks.isNotEmpty ? _businessBooks.first : null;
    }
    
    // Delete from Firestore if online - FIXED: use correct method name
    if (_isCloudConnected) {
      await _firebaseService.deleteBusinessBookFromCloud(bookId); // Changed from deleteBookFromCloud
      print('Book deleted from cloud: $bookId');
    }
    
    notifyListeners();
    print('Book deleted successfully: $bookId');
    
  } catch (e) {
    _lastError = 'Error deleting book: $e';
    print('Error deleting book: $e');
    throw Exception('Failed to delete book: $e');
  } finally {
    _setLoading(false);
  }
}


  // Check if user is the owner of the current book
  bool get isCurrentBookOwner {
    if (_currentBook == null || _currentUserProfile == null) return false;
    return _currentBook!.teamMembers.any((member) => 
      member.userId == _currentUserProfile!.userId && member.role == 'owner');
  }

  // Get books that need sync (for offline-first approach)
  List<BusinessBook> getBooksNeedingSync() {
    // This would track which books have local changes not synced to cloud
    // For now, return all books as potentially needing sync
    return _businessBooks;
  }

  // Check if user can delete a book (only owners can delete)
  bool canDeleteBook(String bookId) {
    final book = getBookById(bookId);
    if (book == null || _currentUserProfile == null) return false;
    
    return book.teamMembers.any((member) => 
      member.userId == _currentUserProfile!.userId && 
      member.role == 'owner' && 
      member.isActive
    );
  }

  // Get all books owned by the current user
  List<BusinessBook> getOwnedBooks() {
    if (_currentUserProfile == null) return [];
    
    return _businessBooks.where((book) => 
      book.teamMembers.any((member) => 
        member.userId == _currentUserProfile!.userId && 
        member.role == 'owner' && 
        member.isActive
      )
    ).toList();
  }

  // Get all books where user is a member (not necessarily owner)
  List<BusinessBook> getMemberBooks() {
    if (_currentUserProfile == null) return [];
    
    return _businessBooks.where((book) => 
      book.teamMembers.any((member) => 
        member.userId == _currentUserProfile!.userId && 
        member.isActive
      )
    ).toList();
  }
}