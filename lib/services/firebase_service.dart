import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Initialize Firebase
  Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();
      
      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  // Check if Firebase is initialized
  bool get isInitialized => _auth != null;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

// ==================== AUTHENTICATION SERVICE ====================

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('❌ User creation failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
      debugPrint('✅ User profile updated successfully');
    } catch (e) {
      debugPrint('❌ Profile update failed: $e');
      rethrow;
    }
  }

  // Sign in with Google - Temporarily disabled due to version compatibility
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In temporarily disabled. Please use email/password login.');
  }

  // Logout method (alias for signOut)
  Future<void> logout() async {
    return await signOut();
  }

  // Check user permission
  Future<bool> hasPermission(String permission) async {
    // For now, return true for all users
    // In a real app, you would check against user roles/permissions
    return true;
  }

  // Get user permissions
  Future<List<String>> getUserPermissions(String role) async {
    // For now, return basic permissions
    // In a real app, you would fetch from Firestore based on role
    return ['read', 'write', 'delete'];
  }
}

// ==================== FIRESTORE SERVICE ====================

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user document reference
  DocumentReference<Map<String, dynamic>> getUserDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // Get documents collection reference
  CollectionReference<Map<String, dynamic>> getDocumentsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('documents');
  }

  // Get questions collection reference
  CollectionReference<Map<String, dynamic>> getQuestionsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('questions');
  }

  // Create or update user document
  Future<void> createOrUpdateUser({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await getUserDoc(userId).set(userData, SetOptions(merge: true));
      debugPrint('✅ User document created/updated successfully');
    } catch (e) {
      debugPrint('❌ User document operation failed: $e');
      rethrow;
    }
  }

  // Get user document
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    try {
      final doc = await getUserDoc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Get user document failed: $e');
      rethrow;
    }
  }

  // Add document
  Future<DocumentReference> addDocument({
    required String userId,
    required Map<String, dynamic> documentData,
  }) async {
    try {
      final docRef = await getDocumentsCollection(userId).add(documentData);
      debugPrint('✅ Document added successfully with ID: ${docRef.id}');
      return docRef;
    } catch (e) {
      debugPrint('❌ Add document failed: $e');
      rethrow;
    }
  }

  // Get user documents
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserDocuments(String userId) {
    return getDocumentsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add question
  Future<DocumentReference> addQuestion({
    required String userId,
    required Map<String, dynamic> questionData,
  }) async {
    try {
      final docRef = await getQuestionsCollection(userId).add(questionData);
      debugPrint('✅ Question added successfully with ID: ${docRef.id}');
      return docRef;
    } catch (e) {
      debugPrint('❌ Add question failed: $e');
      rethrow;
    }
  }

  // Get user questions
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserQuestions(String userId) {
    return getQuestionsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

// ==================== STORAGE SERVICE ====================

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get user storage reference
  Reference getUserStorageRef(String userId) {
    return _storage.ref().child('users').child(userId);
  }

  // Get documents storage reference
  Reference getDocumentsStorageRef(String userId) {
    return getUserStorageRef(userId).child('documents');
  }

  // Get images storage reference
  Reference getImagesStorageRef(String userId) {
    return getUserStorageRef(userId).child('images');
  }

  // Upload file
  Future<String> uploadFile({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    String? folder,
  }) async {
    try {
      final ref = folder != null
          ? getUserStorageRef(userId).child(folder).child(fileName)
          : getUserStorageRef(userId).child(fileName);

      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ File upload failed: $e');
      rethrow;
    }
  }

  // Delete file
  Future<void> deleteFile({
    required String userId,
    required String fileName,
    String? folder,
  }) async {
    try {
      final ref = folder != null
          ? getUserStorageRef(userId).child(folder).child(fileName)
          : getUserStorageRef(userId).child(fileName);

      await ref.delete();
      debugPrint('✅ File deleted successfully: $fileName');
    } catch (e) {
      debugPrint('❌ File deletion failed: $e');
      rethrow;
    }
  }

  // Get file download URL
  Future<String> getFileDownloadUrl({
    required String userId,
    required String fileName,
    String? folder,
  }) async {
    try {
      final ref = folder != null
          ? getUserStorageRef(userId).child(folder).child(fileName)
          : getUserStorageRef(userId).child(fileName);

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Get download URL failed: $e');
      rethrow;
    }
  }
}
