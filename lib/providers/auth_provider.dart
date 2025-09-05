import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? photoURL;
  final String role;
  final String? institution;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    required this.role,
    this.institution,
    this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'] ?? json['photo_url'],
      role: json['role'] ?? 'user',
      institution: json['institution'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'role': role,
      'institution': institution,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoURL,
    String? role,
    String? institution,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      institution: institution ?? this.institution,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }
}

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;
  DateTime? _tokenExpiry;

  // Getters
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get isTokenExpired => _tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!);

  // Initialize auth state
  Future<void> initialize() async {
    try {
      setLoading(true);
      
      // Check Firebase auth state
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await _handleFirebaseUser(firebaseUser);
      }
      
      // Check stored tokens
      await _loadStoredTokens();
      
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Firebase Authentication
  Future<void> loginWithFirebase(firebase_auth.UserCredential userCredential) async {
    try {
      setLoading(true);
      _clearError();
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      await _handleFirebaseUser(firebaseUser);
      
      // Store user data locally
      await _storeUserData();
      
      notifyListeners();
    } catch (e) {
      _setError('Firebase login failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _handleFirebaseUser(firebase_auth.User firebaseUser) async {
    // Create user object from Firebase user
    _currentUser = User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      photoURL: firebaseUser.photoURL,
      role: 'user', // Default role
      institution: null,
      createdAt: firebaseUser.metadata.creationTime,
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );

    // Get Firebase ID token
    final idToken = await firebaseUser.getIdToken();
    _accessToken = idToken;
    
    // Set token expiry (Firebase tokens expire in 1 hour)
    _tokenExpiry = DateTime.now().add(Duration(hours: 1));
  }

  // Email/Password Authentication
  Future<void> loginWithEmail(String accessToken, Map<String, dynamic> userData) async {
    try {
      setLoading(true);
      _clearError();
      
      _accessToken = accessToken;
      _currentUser = User.fromJson(userData);
      
      // Set token expiry (JWT tokens typically expire in 15 minutes)
      _tokenExpiry = DateTime.now().add(Duration(minutes: 15));
      
      // Store user data locally
      await _storeUserData();
      
      notifyListeners();
    } catch (e) {
      _setError('Email login failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Registration
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? institution,
  }) async {
    try {
      setLoading(true);
      _clearError();

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'institution': institution,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await loginWithEmail(data['accessToken'], data['user']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      setLoading(true);
      
      // Sign out from Firebase
      await firebase_auth.FirebaseAuth.instance.signOut();
      
      // Clear local data
      _clearUserData();
      
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Refresh Token
  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['accessToken'];
        _tokenExpiry = DateTime.now().add(Duration(minutes: 15));
        
        // Store updated tokens
        await _storeUserData();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: ${e.toString()}');
      return false;
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      setLoading(true);
      _clearError();

      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Update Profile
  Future<void> updateProfile({
    String? name,
    String? institution,
    String? photoURL,
  }) async {
    try {
      setLoading(true);
      _clearError();

      if (_currentUser == null) {
        throw Exception('No user logged in');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'name': name,
          'institution': institution,
          'photoURL': photoURL,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = _currentUser!.copyWith(
          name: data['name'] ?? _currentUser!.name,
          institution: data['institution'] ?? _currentUser!.institution,
          photoURL: data['photoURL'] ?? _currentUser!.photoURL,
        );
        
        await _storeUserData();
        notifyListeners();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      setLoading(true);
      _clearError();

      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Password change failed');
      }
    } catch (e) {
      _setError('Password change failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      setLoading(true);
      _clearError();

      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        await logout();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Account deletion failed');
      }
    } catch (e) {
      _setError('Account deletion failed: ${e.toString()}');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  bool hasAnyRole(List<String> roles) {
    return _currentUser != null && roles.contains(_currentUser!.role);
  }

  // Check if user has permission
  bool hasPermission(String permission) {
    // Implement permission checking logic here
    // For now, just check if user is admin
    return hasRole('admin');
  }

  // Private methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _clearUserData() {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  // Local storage methods (implement with your preferred storage solution)
  Future<void> _storeUserData() async {
    // TODO: Implement local storage (SharedPreferences, Hive, etc.)
    // Store user data, tokens, and expiry
  }

  Future<void> _loadStoredTokens() async {
    // TODO: Implement local storage loading
    // Load stored tokens and check if they're still valid
  }

  // Auto-refresh token when needed
  Future<void> ensureValidToken() async {
    if (isTokenExpired && _refreshToken != null) {
      await _refreshAccessToken();
    }
  }

  // Get headers for API requests
  Map<String, String> getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
  }

  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
}
