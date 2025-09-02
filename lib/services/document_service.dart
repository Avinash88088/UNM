import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/document_model.dart';
import '../models/question_model.dart';

class DocumentService {
  final ApiClient _apiClient;

  DocumentService(this._apiClient);

  // Get all documents for current user
  Future<List<Document>> getDocuments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? search,
  }) async {
    try {
      String endpoint = '/documents?page=$page&limit=$limit';
      
      if (status != null) endpoint += '&status=$status';
      if (type != null) endpoint += '&type=$type';
      if (search != null) endpoint += '&search=$search';

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documentsJson = data['documents'];
        
        return documentsJson.map((json) => Document.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch documents');
      }
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // Upload a new document
  Future<Document> uploadDocument({
    required File file,
    required String title,
    String? description,
    String? language,
    List<String> features = const ['ocr'],
    Map<String, dynamic>? processingOptions,
    Function(double)? onProgress,
  }) async {
    try {
      // Prepare form data
      final fields = <String, String>{
        'title': title,
        'features': features.join(','),
      };

      if (description != null) fields['description'] = description;
      if (language != null) fields['language'] = language;
      if (processingOptions != null) {
        fields['processingOptions'] = jsonEncode(processingOptions);
      }

      final response = await _apiClient.uploadFile(
        '/documents',
        file.path,
        fields: fields,
        onProgress: onProgress,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Document.fromJson(data['document']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Document upload failed');
      }
    } catch (e) {
      throw Exception('Document upload failed: $e');
    }
  }

  // Get a specific document by ID
  Future<Document> getDocument(String documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Document.fromJson(data['document']);
      } else {
        throw Exception('Failed to fetch document');
      }
    } catch (e) {
      throw Exception('Failed to fetch document: $e');
    }
  }

  // Update document metadata
  Future<Document> updateDocument({
    required String documentId,
    String? title,
    String? description,
    String? language,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (language != null) body['language'] = language;
      if (metadata != null) body['metadata'] = metadata;

      final response = await _apiClient.put(
        '/documents/$documentId',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Document.fromJson(data['document']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Document update failed');
      }
    } catch (e) {
      throw Exception('Document update failed: $e');
    }
  }

  // Delete a document
  Future<void> deleteDocument(String documentId) async {
    try {
      final response = await _apiClient.delete('/documents/$documentId');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Document deletion failed');
      }
    } catch (e) {
      throw Exception('Document deletion failed: $e');
    }
  }

  // Process document with AI services
  Future<Map<String, dynamic>> processDocument({
    required String documentId,
    List<String> features = const ['ocr'],
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _apiClient.post('/ai/process', body: {
        'documentId': documentId,
        'features': features,
        'options': options,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Document processing failed');
      }
    } catch (e) {
      throw Exception('Document processing failed: $e');
    }
  }

  // Generate questions from document
  Future<List<Question>> generateQuestions({
    required String documentId,
    int count = 10,
    String difficulty = 'medium',
    List<String> types = const ['mcq', 'short_answer'],
    String? language,
  }) async {
    try {
      final response = await _apiClient.post('/ai/questions', body: {
        'documentId': documentId,
        'count': count,
        'difficulty': difficulty,
        'types': types,
        'language': language,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> questionsJson = data['questions'];
        
        return questionsJson.map((json) => Question.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Question generation failed');
      }
    } catch (e) {
      throw Exception('Question generation failed: $e');
    }
  }

  // Get document processing status
  Future<Map<String, dynamic>> getProcessingStatus(String documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId/status');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get processing status');
      }
    } catch (e) {
      throw Exception('Failed to get processing status: $e');
    }
  }

  // Get document pages
  Future<List<DocumentPage>> getDocumentPages(String documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId/pages');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> pagesJson = data['pages'];
        
        return pagesJson.map((json) => DocumentPage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch document pages');
      }
    } catch (e) {
      throw Exception('Failed to fetch document pages: $e');
    }
  }

  // Get document analytics
  Future<Map<String, dynamic>> getDocumentAnalytics(String documentId) async {
    try {
      final response = await _apiClient.get('/documents/$documentId/analytics');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch document analytics');
      }
    } catch (e) {
      throw Exception('Failed to fetch document analytics: $e');
    }
  }

  // Share document with other users
  Future<void> shareDocument({
    required String documentId,
    required List<String> userEmails,
    String permission = 'read',
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _apiClient.post('/documents/$documentId/share', body: {
        'userEmails': userEmails,
        'permission': permission,
        'expiresAt': expiresAt?.toIso8601String(),
      });

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Document sharing failed');
      }
    } catch (e) {
      throw Exception('Document sharing failed: $e');
    }
  }

  // Get shared documents
  Future<List<Document>> getSharedDocuments() async {
    try {
      final response = await _apiClient.get('/documents/shared');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documentsJson = data['documents'];
        
        return documentsJson.map((json) => Document.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch shared documents');
      }
    } catch (e) {
      throw Exception('Failed to fetch shared documents: $e');
    }
  }

  // Batch upload multiple documents
  Future<List<Document>> batchUploadDocuments({
    required List<File> files,
    required String title,
    String? description,
    String? language,
    List<String> features = const ['ocr'],
    Map<String, dynamic>? processingOptions,
    Function(int, double)? onProgress,
  }) async {
    try {
      final documents = <Document>[];
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final progress = (i + 1) / files.length;
        
        if (onProgress != null) {
          onProgress(i + 1, progress);
        }

        final document = await uploadDocument(
          file: file,
          title: '$title (${i + 1})',
          description: description,
          language: language,
          features: features,
          processingOptions: processingOptions,
        );

        documents.add(document);
      }

      return documents;
    } catch (e) {
      throw Exception('Batch upload failed: $e');
    }
  }

  // Export document in different formats
  Future<File> exportDocument({
    required String documentId,
    required String format, // 'pdf', 'docx', 'txt'
    Map<String, dynamic>? options,
  }) async {
    try {
      final response = await _apiClient.post('/documents/$documentId/export', body: {
        'format': format,
        'options': options,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final downloadUrl = data['downloadUrl'];
        
        // Download the file
        final fileResponse = await http.get(Uri.parse(downloadUrl));
        final fileName = 'document_$documentId.$format';
        final file = File(fileName);
        await file.writeAsBytes(fileResponse.bodyBytes);
        
        return file;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Document export failed');
      }
    } catch (e) {
      throw Exception('Document export failed: $e');
    }
  }
}
