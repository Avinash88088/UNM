import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration timeout = Duration(seconds:30);
  
  String? _accessToken;
  String? _refreshToken;
  
  // Initialize tokens from storage
  Future<void> initialize() async {
    await _loadTokens();
  }
  
  // Load tokens from SharedPreferences
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }
  
  // Save tokens to SharedPreferences
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }
  
  // Clear all tokens
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  // Get headers with authentication
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }
  
  // GET request
  Future<http.Response> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
        ).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }
  
  // POST request
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }
  
  // PUT request
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }
  
  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        return await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: _headers,
        ).timeout(timeout);
      }
      
      return response;
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }
  
  // File upload with progress tracking
  Future<http.Response> uploadFile(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    Function(double)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);
      request.headers.remove('Content-Type'); // Let multipart set this
      
      // Add file
      final file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);
      
      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Send request
      final streamedResponse = await request.send().timeout(timeout);
      
      // Convert to regular response
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        // Retry with new token
        return await uploadFile(endpoint, filePath, fields: fields, onProgress: onProgress);
      }
      
      return response;
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }
  
  // Refresh access token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        await _saveTokens();
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      await clearTokens();
      throw Exception('Token refresh failed: $e');
    }
  }
  
  // Set tokens (for login)
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _saveTokens();
  }
  
  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;
  
  // Get current access token
  String? get accessToken => _accessToken;
  
  // Dispose resources
  void dispose() {
    _accessToken = null;
    _refreshToken = null;
  }
}
