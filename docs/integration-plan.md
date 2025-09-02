# AI Document Master - Frontend-Backend Integration Plan

## 🎯 Overview

This document outlines the complete integration plan between the Flutter frontend and Node.js backend for the AI Document Master application. The integration will enable real-time document processing, AI-powered question generation, and seamless user experience.

## 🔗 Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Frontend                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐  │
│  │   Screens   │ │   Widgets   │ │   Models    │ │Services │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   HTTP Client   │
                    │   (API Client)  │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   WebSocket     │
                    │   (Socket.io)   │
                    └─────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Node.js Backend                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────┐  │
│  │    Routes   │ │Controllers  │ │   Models    │ │Services │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 📱 Flutter Frontend Integration

### 1. API Client Service

#### File: `lib/services/api_client.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  static const Duration timeout = Duration(seconds: 30);
  
  late final http.Client _client;
  String? _accessToken;
  String? _refreshToken;
  
  ApiClient() {
    _client = http.Client();
    _loadTokens();
  }
  
  // Load tokens from local storage
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }
  
  // Save tokens to local storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  
  // Clear tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
  }
  
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }
  
  // HTTP Methods with automatic token refresh
  Future<http.Response> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.get(uri, headers: _headers).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await _client.get(uri, headers: _headers).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<http.Response> post(String endpoint, {Object? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await _client.post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<http.Response> put(String endpoint, {Object? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await _client.put(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<http.Response> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.delete(uri, headers: _headers).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await _client.delete(uri, headers: _headers).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // File upload with progress
  Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String filePath, {
    Map<String, String> fields = const {},
    void Function(int, int)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);
      
      // Add fields
      request.fields.addAll(fields);
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      // Send request with progress tracking
      final response = await request.send();
      
      // Track progress
      int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      
      response.stream.listen(
        (List<int> chunk) {
          receivedBytes += chunk.length;
          if (onProgress != null) {
            onProgress!(receivedBytes, totalBytes);
          }
        },
        onDone: () {
          if (onProgress != null) {
            onProgress!(totalBytes, totalBytes);
          }
        },
      );
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // Refresh access token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = data['data']['tokens'];
        await _saveTokens(tokens['accessToken'], tokens['refreshToken']);
      } else {
        await clearTokens();
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      await clearTokens();
      rethrow;
    }
  }
  
  // Close client
  void dispose() {
    _client.close();
  }
}
```

### 2. Authentication Service

#### File: `lib/services/auth_service.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;
  
  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['data']['user']);
        final tokens = data['data']['tokens'];
        
        // Save tokens
        await _apiClient._saveTokens(tokens['accessToken'], tokens['refreshToken']);
        
        return {
          'success': true,
          'user': user,
          'tokens': tokens,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String role = 'student',
    String? institutionId,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': role,
        'institutionId': institutionId,
      });
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['data']['user']),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['data']['user']);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Continue with local cleanup even if API call fails
    } finally {
      await _apiClient.clearTokens();
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }
  
  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Password change failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
```

### 3. Document Service

#### File: `lib/services/document_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/document_model.dart';

class DocumentService {
  final ApiClient _apiClient;
  
  DocumentService({required ApiClient apiClient}) : _apiClient = apiClient;
  
  // Get documents with pagination and filters
  Future<List<Document>> getDocuments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? language,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (language != null) queryParams['language'] = language;
      
      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiClient.get('/documents?$queryString');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((json) => Document.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Upload document
  Future<Document> uploadDocument({
    required File file,
    required String compressionProfile,
    required List<String> features,
    String language = 'en',
    String priority = 'normal',
    void Function(int, int)? onProgress,
  }) async {
    try {
      final fields = {
        'compressionProfile': compressionProfile,
        'features': features.join(','),
        'language': language,
        'priority': priority,
      };
      
      final response = await _apiClient.uploadFile(
        '/documents/upload',
        file.path,
        fields: fields,
        onProgress: onProgress,
      );
      
      if (response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        return Document.fromJson(jsonDecode(responseData));
      } else {
        final responseData = await response.stream.bytesToString();
        final error = jsonDecode(responseData);
        throw Exception('Upload failed: ${error['error']}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get document details
  Future<Document> getDocument(String documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Document.fromJson(data['data']);
      } else {
        throw Exception('Failed to load document');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update document
  Future<Document> updateDocument({
    required String documentId,
    String? fileName,
    String? language,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fileName != null) body['fileName'] = fileName;
      if (language != null) body['language'] = language;
      if (metadata != null) body['metadata'] = metadata;
      
      final response = await _apiClient.put('/documents/$documentId', body: body);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Document.fromJson(data['data']);
      } else {
        throw Exception('Failed to update document');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      final response = await _apiClient.delete('/documents/$documentId');
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Process document with AI
  Future<void> processDocument({
    required String documentId,
    required List<String> features,
    String language = 'en',
    String priority = 'normal',
  }) async {
    try {
      final response = await _apiClient.post('/ai/process-document', body: {
        'documentId': documentId,
        'features': features,
        'language': language,
        'priority': priority,
      });
      
      if (response.statusCode != 200) {
        throw Exception('Failed to start document processing');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Generate questions from document
  Future<List<Question>> generateQuestions({
    required String documentId,
    int questionCount = 20,
    String difficulty = 'medium',
    List<String> types = const ['multiple_choice', 'short_answer'],
    String? subject,
    String? grade,
  }) async {
    try {
      final response = await _apiClient.post('/ai/generate-questions', body: {
        'documentId': documentId,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'types': types,
        'subject': subject,
        'grade': grade,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> questions = data['data']['questions'];
        return questions.map((json) => Question.fromJson(json)).toList();
      } else {
        throw Exception('Failed to generate questions');
      }
    } catch (e) {
      rethrow;
    }
  }
}
```

### 4. WebSocket Service

#### File: `lib/services/socket_service.dart`

```dart
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  late IO.Socket _socket;
  bool _isConnected = false;
  final String _serverUrl = 'http://localhost:3000';
  
  // Event callbacks
  Function(String, int, String)? onProcessingUpdate;
  Function(String, String)? onJobStatusChange;
  Function(String, Map<String, dynamic>)? onNotification;
  
  // Initialize socket connection
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      _socket = IO.io(_serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': accessToken},
      });
      
      _setupEventListeners();
      _connect();
    } catch (e) {
      rethrow;
    }
  }
  
  // Setup event listeners
  void _setupEventListeners() {
    _socket.onConnect((_) {
      _isConnected = true;
      print('Socket connected');
    });
    
    _socket.onDisconnect((_) {
      _isConnected = false;
      print('Socket disconnected');
    });
    
    _socket.onConnectError((error) {
      print('Socket connection error: $error');
    });
    
    // Document processing updates
    _socket.on('processing-update', (data) {
      if (onProcessingUpdate != null) {
        final update = jsonDecode(data);
        onProcessingUpdate!(
          update['documentId'],
          update['progress'],
          update['status'],
        );
      }
    });
    
    // Job status changes
    _socket.on('job-status-change', (data) {
      if (onJobStatusChange != null) {
        final change = jsonDecode(data);
        onJobStatusChange!(
          change['jobId'],
          change['status'],
        );
      }
    });
    
    // General notifications
    _socket.on('notification', (data) {
      if (onNotification != null) {
        final notification = jsonDecode(data);
        onNotification!(
          notification['type'],
          notification['data'],
        );
      }
    });
  }
  
  // Connect to socket
  void _connect() {
    if (!_isConnected) {
      _socket.connect();
    }
  }
  
  // Disconnect from socket
  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
    }
  }
  
  // Join document room for updates
  void joinDocument(String documentId) {
    if (_isConnected) {
      _socket.emit('join-document', documentId);
    }
  }
  
  // Leave document room
  void leaveDocument(String documentId) {
    if (_isConnected) {
      _socket.emit('leave-document', documentId);
    }
  }
  
  // Check connection status
  bool get isConnected => _isConnected;
  
  // Dispose service
  void dispose() {
    disconnect();
    _socket.dispose();
  }
}
```

## 🔄 State Management Integration

### 1. Provider Setup

#### File: `lib/providers/app_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/socket_service.dart';
import '../models/user_model.dart';

class AppProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  late final AuthService _authService;
  late final DocumentService _documentService;
  late final SocketService _socketService;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  AppProvider() {
    _authService = AuthService(apiClient: _apiClient);
    _documentService = DocumentService(apiClient: _apiClient);
    _socketService = SocketService();
    _initializeApp();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  
  // Initialize app
  Future<void> _initializeApp() async {
    try {
      _setLoading(true);
      
      // Check if user is logged in
      if (await _authService.isLoggedIn()) {
        _currentUser = await _authService.getCurrentUser();
        if (_currentUser != null) {
          await _socketService.initialize();
        }
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.login(email, password);
      
      if (result['success']) {
        _currentUser = result['user'];
        await _socketService.initialize();
        notifyListeners();
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String role = 'student',
    String? institutionId,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: role,
        institutionId: institutionId,
      );
      
      if (result['success']) {
        _setError(null);
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _socketService.disconnect();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  @override
  void dispose() {
    _socketService.dispose();
    _apiClient.dispose();
    super.dispose();
  }
}
```

### 2. Main App Integration

#### File: `lib/main.dart` (Updated)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/question_generator_screen.dart';
import 'screens/batch_management_screen.dart';
import 'screens/admin_console_screen.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AIDocumentMasterApp());
}

class AIDocumentMasterApp extends StatelessWidget {
  const AIDocumentMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'AI Document Master',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          AppRoutes.dashboard: (context) => const DashboardScreen(),
          AppRoutes.upload: (context) => const UploadScreen(),
          AppRoutes.documentViewer: (context) => const DocumentViewerScreen(),
          AppRoutes.questionGenerator: (context) => const QuestionGeneratorScreen(),
          AppRoutes.batchManagement: (context) => const BatchManagementScreen(),
          AppRoutes.adminConsole: (context) => const AdminConsoleScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (appProvider.isLoggedIn) {
          return const DashboardScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
```

## 🚀 Integration Steps

### Phase 1: Basic Setup (Week 1)

1. **Install Dependencies**
   ```bash
   # Flutter dependencies
   flutter pub add provider http shared_preferences socket_io_client
   
   # Backend dependencies
   cd backend
   npm install
   ```

2. **Environment Configuration**
   - Copy `backend/env.example` to `backend/.env`
   - Configure database, Redis, and API keys
   - Update Flutter API client base URL

3. **Database Setup**
   ```bash
   cd backend
   docker-compose up -d postgres redis
   # Wait for services to be healthy
   docker-compose up -d api
   ```

### Phase 2: Authentication Integration (Week 2)

1. **Implement Auth Service**
   - Complete `AuthService` implementation
   - Add login/register screens
   - Integrate with `AppProvider`

2. **Token Management**
   - Implement automatic token refresh
   - Add secure token storage
   - Handle authentication errors

3. **Protected Routes**
   - Add authentication guards
   - Implement role-based navigation
   - Add logout functionality

### Phase 3: Core Features (Week 3-4)

1. **Document Management**
   - Implement document upload
   - Add document listing and details
   - Integrate with backend API

2. **Real-time Updates**
   - Setup WebSocket connection
   - Implement progress tracking
   - Add live notifications

3. **AI Processing**
   - Integrate OCR and HWR
   - Add question generation
   - Implement batch processing

### Phase 4: Advanced Features (Week 5-6)

1. **User Management**
   - Add user profiles
   - Implement role management
   - Add institution support

2. **Batch Processing**
   - Implement batch uploads
   - Add progress tracking
   - Handle multiple documents

3. **Question Management**
   - Create question sets
   - Add question editing
   - Implement question sharing

### Phase 5: Testing & Optimization (Week 7-8)

1. **Testing**
   - Unit tests for services
   - Integration tests for API
   - UI testing for screens

2. **Performance**
   - Optimize API calls
   - Implement caching
   - Add error handling

3. **Deployment**
   - Production environment setup
   - SSL configuration
   - Monitoring and logging

## 🔧 Configuration Files

### 1. Flutter Dependencies

#### File: `pubspec.yaml` (Updated)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # HTTP & API
  http: ^1.1.0
  
  # Local Storage
  shared_preferences: ^2.2.2
  
  # WebSocket
  socket_io_client: ^2.0.3+1
  
  # File Handling
  file_picker: ^6.1.1
  image_picker: ^1.0.4
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Utilities
  uuid: ^4.2.1
  intl: ^0.18.1
  path_provider: ^2.1.1
  
  # Development
  cupertino_icons: ^1.0.2
```

### 2. Environment Configuration

#### File: `lib/config/app_config.dart`

```dart
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const String wsBaseUrl = 'http://localhost:3000';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 10);
  
  // File Limits
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> supportedFormats = [
    'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'tiff'
  ];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Development
  static const bool enableLogging = true;
  static const bool enableDebugMode = true;
}
```

## 🧪 Testing Strategy

### 1. Unit Tests

```bash
# Test services
flutter test test/services/

# Test models
flutter test test/models/

# Test utilities
flutter test test/utils/
```

### 2. Integration Tests

```bash
# Test API integration
flutter test test/integration/

# Test WebSocket
flutter test test/websocket/
```

### 3. Widget Tests

```bash
# Test UI components
flutter test test/widgets/

# Test screens
flutter test test/screens/
```

## 📱 Mobile Optimization

### 1. Offline Support
- Cache API responses
- Queue offline actions
- Sync when online

### 2. Performance
- Image compression
- Lazy loading
- Background processing

### 3. User Experience
- Loading states
- Error handling
- Progress indicators

## 🔒 Security Considerations

### 1. API Security
- HTTPS only in production
- Token expiration
- Rate limiting

### 2. Data Protection
- Encrypt sensitive data
- Secure token storage
- Input validation

### 3. Privacy
- User consent
- Data retention
- GDPR compliance

## 🚀 Deployment Checklist

### 1. Backend Deployment
- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] SSL certificates installed
- [ ] Monitoring configured
- [ ] Backup strategy implemented

### 2. Frontend Deployment
- [ ] API endpoints updated
- [ ] Build configuration set
- [ ] App signing configured
- [ ] Store listings prepared
- [ ] Analytics configured

### 3. Integration Testing
- [ ] End-to-end tests passing
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] User acceptance testing done

---

This integration plan provides a comprehensive roadmap for connecting your Flutter frontend with the Node.js backend. Follow the phases sequentially to ensure a smooth integration process. Each phase builds upon the previous one, creating a solid foundation for the complete AI Document Master application.
