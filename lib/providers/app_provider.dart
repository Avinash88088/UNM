import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/advanced_ocr_service.dart';
import '../services/image_processing_service.dart';
import '../services/socket_service.dart';
import '../models/document_model.dart';
import '../models/question_model.dart';
import 'auth_provider.dart';

class AppProvider extends ChangeNotifier {
  // State
  firebase_auth.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  
  // Services
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final DocumentService _documentService;
  late final AdvancedOCRService _advancedOCRService;
  late final ImageProcessingService _imageProcessingService;
  late final SocketService _socketService;

  // Getters
  firebase_auth.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;
  
  // Service getters
  ApiClient get apiClient => _apiClient;
  AuthService get authService => _authService;
  DocumentService get documentService => _documentService;
  AdvancedOCRService get advancedOCRService => _advancedOCRService;
  ImageProcessingService get imageProcessingService => _imageProcessingService;
  SocketService get socketService => _socketService;

  // Constructor
  AppProvider() {
    _initializeServices();
  }

  // Initialize all services
  Future<void> _initializeServices() async {
    try {
      _setLoading(true);
      _clearError();

      // Initialize API client
      _apiClient = ApiClient();
      await _apiClient.initialize();

      // Initialize services
      _authService = AuthService(_apiClient);
      _documentService = DocumentService(_apiClient);
      _advancedOCRService = AdvancedOCRService(_apiClient);
      _imageProcessingService = ImageProcessingService(_apiClient);
      _socketService = SocketService();

      // Check if user is already logged in
      _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      
      // Listen to auth state changes
      firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? user) {
        _currentUser = user;
        notifyListeners();
      });

      // Initialize socket connection if user is logged in
      if (_currentUser != null) {
        await _socketService.connect();
      }

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

      // Use backend authentication
      final user = await _authService.login(email: email, password: password);
      
      // Also sign in with Firebase for consistency
      final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;

      // Connect to socket for real-time updates
      await _socketService.connect();

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

      // Use backend registration
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      
      // Also create Firebase user for consistency
      final userCredential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);
      
      _currentUser = userCredential.user;

      // Connect to socket for real-time updates
      await _socketService.connect();

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
      // Disconnect socket
      await _socketService.disconnect();
      
      // Logout from backend
      await _authService.logout();
      
      // Logout from Firebase
      await firebase_auth.FirebaseAuth.instance.signOut();
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

  // Document management methods
  Future<void> uploadDocument({
    required String filePath,
    required String title,
    String? description,
    String? language,
    List<String> features = const ['ocr'],
    Function(double)? onProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final file = File(filePath);
      final document = await _documentService.uploadDocument(
        file: file,
        title: title,
        description: description,
        language: language,
        features: features,
        onProgress: onProgress,
      );

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Document upload failed: $e');
      _setLoading(false);
    }
  }

  // OCR processing methods
  Future<OCRResult> processOCR({
    required String imagePath,
    String? language,
    bool enhanceImage = true,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final file = File(imagePath);
      final result = await _advancedOCRService.extractText(
        imageFile: file,
        language: language,
        enhanceImage: enhanceImage,
      );

      _setLoading(false);
      notifyListeners();
      return result;
    } catch (e) {
      _setError('OCR processing failed: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // Question generation methods
  Future<List<Question>> generateQuestions({
    required String documentId,
    int count = 10,
    String difficulty = 'medium',
    List<String> types = const ['mcq', 'short_answer'],
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final questions = await _documentService.generateQuestions(
        documentId: documentId,
        count: count,
        difficulty: difficulty,
        types: types,
      );

      _setLoading(false);
      notifyListeners();
      return questions;
    } catch (e) {
      _setError('Question generation failed: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _socketService.disconnect();
    _apiClient.dispose();
    super.dispose();
  }
}
