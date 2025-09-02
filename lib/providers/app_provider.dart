import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppProvider extends ChangeNotifier {
  // State
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;
  
  // Service getters (temporary stubs)
  dynamic get apiClient => null;
  dynamic get imageProcessingService => null;
  dynamic get advancedOCRService => null;

  // Constructor
  AppProvider() {
    _initializeServices();
  }

  // Initialize basic services
  Future<void> _initializeServices() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if user is already logged in
      _currentUser = FirebaseAuth.instance.currentUser;
      
      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _currentUser = user;
        notifyListeners();
      });

      _setLoading(false);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Initialization failed: $e');
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Authentication methods
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);
      
      _currentUser = userCredential.user;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In temporarily disabled. Please use email/password login.');
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
    }
  }

  // Check if user has permission
  Future<bool> hasPermission(String permission) async {
    // For now, return true for all users
    return true;
  }

  // Get user permissions
  Future<List<String>> getUserPermissions() async {
    // For now, return basic permissions
    return ['read', 'write', 'delete'];
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}
