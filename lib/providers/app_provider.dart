import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/socket_service.dart';
import '../models/document_model.dart';
import '../models/question_model.dart';

class AppProvider extends ChangeNotifier {
  // Services
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final DocumentService _documentService;
  late final SocketService _socketService;

  // State
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<Document> _documents = [];
  List<Question> _questions = [];
  bool _isInitialized = false;

  // Getters
  ApiClient get apiClient => _apiClient;
  AuthService get authService => _authService;
  DocumentService get documentService => _documentService;
  SocketService get socketService => _socketService;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Document> get documents => _documents;
  List<Question> get questions => _questions;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _authService.isLoggedIn;

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

      // Initialize other services
      _authService = AuthService(_apiClient);
      _documentService = DocumentService(_apiClient);
      _socketService = SocketService();

      // Check if user is already logged in
      if (_authService.isLoggedIn) {
        await _loadCurrentUser();
      }

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize app: $e');
      _setLoading(false);
    }
  }

  // Load current user data
  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      await _loadUserData();
      notifyListeners();
    } catch (e) {
      // User token might be expired, clear it
      await _authService.logout();
      _currentUser = null;
      _clearUserData();
    }
  }

  // Load user's documents and other data
  Future<void> _loadUserData() async {
    try {
      await Future.wait([
        _loadDocuments(),
        _loadQuestions(),
      ]);
    } catch (e) {
      // Handle error silently for now
      debugPrint('Failed to load user data: $e');
    }
  }

  // Load user documents
  Future<void> _loadDocuments() async {
    try {
      _documents = await _documentService.getDocuments();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load documents: $e');
    }
  }

  // Load user questions
  Future<void> _loadQuestions() async {
    try {
      // This would need to be implemented based on your question service
      // For now, we'll leave it empty
      _questions = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load questions: $e');
    }
  }

  // Clear user data
  void _clearUserData() {
    _documents = [];
    _questions = [];
    notifyListeners();
  }

  // Authentication methods
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.login(email: email, password: password);
      _currentUser = user;

      // Connect to socket service
      await _socketService.initialize();
      await _socketService.connect();

      // Load user data
      await _loadUserData();

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
    String? institutionId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        institutionId: institutionId,
      );
      _currentUser = user;

      // Connect to socket service
      await _socketService.initialize();
      await _socketService.connect();

      // Load user data
      await _loadUserData();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);

      // Disconnect socket
      await _socketService.disconnect();

      // Logout from service
      await _authService.logout();

      // Clear local state
      _currentUser = null;
      _clearUserData();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
      _setLoading(false);
    }
  }

  // Document methods
  Future<bool> uploadDocument({
    required String filePath,
    required String title,
    String? description,
    String? language,
    List<String> features = const ['ocr'],
    Map<String, dynamic>? processingOptions,
    Function(double)? onProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Import dart:io for File
      import 'dart:io';
      final file = File(filePath);

      final document = await _documentService.uploadDocument(
        file: file,
        title: title,
        description: description,
        language: language,
        features: features,
        processingOptions: processingOptions,
        onProgress: onProgress,
      );

      // Add to local list
      _documents.insert(0, document);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Document upload failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      _setLoading(true);
      _clearError();

      await _documentService.deleteDocument(documentId);

      // Remove from local list
      _documents.removeWhere((doc) => doc.id == documentId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Document deletion failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> processDocument({
    required String documentId,
    List<String> features = const ['ocr'],
    Map<String, dynamic>? options,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _documentService.processDocument(
        documentId: documentId,
        features: features,
        options: options,
      );

      // Update document status
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index != -1) {
        _documents[index] = _documents[index].copyWith(
          status: DocumentStatus.processing,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Document processing failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> generateQuestions({
    required String documentId,
    int count = 10,
    String difficulty = 'medium',
    List<String> types = const ['mcq', 'short_answer'],
    String? language,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final newQuestions = await _documentService.generateQuestions(
        documentId: documentId,
        count: count,
        difficulty: difficulty,
        types: types,
        language: language,
      );

      // Add to local list
      _questions.addAll(newQuestions);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Question generation failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser != null) {
        await _loadUserData();
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh data: $e');
      _setLoading(false);
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Update current user
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Add document to list
  void addDocument(Document document) {
    _documents.insert(0, document);
    notifyListeners();
  }

  // Update document in list
  void updateDocument(Document document) {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      notifyListeners();
    }
  }

  // Remove document from list
  void removeDocument(String documentId) {
    _documents.removeWhere((doc) => doc.id == documentId);
    notifyListeners();
  }

  // Add question to list
  void addQuestion(Question question) {
    _questions.add(question);
    notifyListeners();
  }

  // Update question in list
  void updateQuestion(Question question) {
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      _questions[index] = question;
      notifyListeners();
    }
  }

  // Remove question from list
  void removeQuestion(String questionId) {
    _questions.removeWhere((q) => q.id == questionId);
    notifyListeners();
  }

  // Check if user has permission
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return _authService.hasPermission(permission);
  }

  // Get user permissions
  List<String> getUserPermissions() {
    if (_currentUser == null) return [];
    return _authService.getUserPermissions(_currentUser!.role);
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
