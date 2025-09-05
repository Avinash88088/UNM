import 'package:flutter/material.dart';

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String upload = '/upload';
  static const String documentViewer = '/document-viewer';
  static const String questionGenerator = '/question-generator';
  static const String batchManagement = '/batch-management';
  static const String batchProcessing = '/batch-processing';
  static const String imageEditor = '/image-editor';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String adminConsole = '/admin-console';
}

class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000';
  static const String apiVersion = '/api';
  
  // App Information
  static const String appName = 'AI Document Master';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Intelligent document processing with AI';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // File Upload
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedFileTypes = [
    'pdf', 'jpg', 'jpeg', 'png', 'tiff', 'doc', 'docx'
  ];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100;
  
  // Security
  static const int minPasswordLength = 8;
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  // Compression Profiles
  static const Map<String, Map<String, dynamic>> compressionProfiles = {
    'high': {
      'name': 'High Quality',
      'quality': 95,
      'maxSize': 5000,
      'description': 'Best quality, larger file size'
    },
    'medium': {
      'name': 'Medium Quality',
      'quality': 85,
      'maxSize': 2000,
      'description': 'Balanced quality and size'
    },
    'low': {
      'name': 'Low Quality',
      'quality': 70,
      'maxSize': 1000,
      'description': 'Smaller file size, lower quality'
    },
  };
}

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF673AB7);
  static const Color secondaryDark = Color(0xFF512DA8);
  static const Color secondaryLight = Color(0xFFD1C4E9);
  
  // Accent Colors
  static const Color accent = Color(0xFFFF9800);
  static const Color accentDark = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFE0B2);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color greyDark = Color(0xFF616161);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);
  static const Color borderDark = Color(0xFFBDBDBD);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x33000000);
}

class AppSizes {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  
  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  
  // Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
  
  // Input Heights
  static const double inputHeightSm = 40.0;
  static const double inputHeightMd = 48.0;
  static const double inputHeightLg = 56.0;
}

class AppStrings {
  // Upload Screen
  static const String uploadTitle = 'Upload Document';
  static const String selectFile = 'Select File';
  static const String captureImage = 'Capture Image';
  static const String chooseProfile = 'Choose Compression Profile';
  
  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String close = 'Close';
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
  
  // Button
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );
}
