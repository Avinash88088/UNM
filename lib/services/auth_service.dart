import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? institutionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.institutionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      institutionId: json['institution_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'institution_id': institutionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? institutionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      institutionId: institutionId ?? this.institutionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // User registration
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? institutionId,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'institution_id': institutionId,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Set tokens
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );

        return User.fromJson(data['user']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // User login
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Set tokens
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );

        return User.fromJson(data['user']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to get current user');
      }
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _apiClient.clearTokens();
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Password change failed');
      }
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => _apiClient.isAuthenticated;

  // Get current access token
  String? get accessToken => _apiClient.accessToken;

  // Refresh tokens
  Future<void> refreshTokens() async {
    try {
      final response = await http.post(
        Uri.parse('${_apiClient.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _apiClient._refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      await _apiClient.clearTokens();
      throw Exception('Token refresh failed: $e');
    }
  }

  // Validate token
  Future<bool> validateToken() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get user permissions based on role
  List<String> getUserPermissions(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return [
          'users:read',
          'users:write',
          'users:delete',
          'documents:read',
          'documents:write',
          'documents:delete',
          'ai:process',
          'admin:access',
        ];
      case 'admin':
        return [
          'users:read',
          'users:write',
          'documents:read',
          'documents:write',
          'documents:delete',
          'ai:process',
        ];
      case 'teacher':
        return [
          'documents:read',
          'documents:write',
          'ai:process',
          'questions:read',
          'questions:write',
        ];
      case 'student':
        return [
          'documents:read',
          'ai:process',
          'questions:read',
        ];
      default:
        return ['documents:read'];
    }
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    if (!isLoggedIn) return false;
    
    try {
      // This would need to be implemented with proper user role checking
      // For now, return true if logged in
      return true;
    } catch (e) {
      return false;
    }
  }
}
