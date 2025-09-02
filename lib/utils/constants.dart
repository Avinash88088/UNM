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
  // File size limits (in MB)
  static const int maxFileSize = 50;
  static const int maxImageSize = 10;
  
  // Supported file types
  static const List<String> supportedImageTypes = [
    'jpg', 'jpeg', 'png', 'tiff', 'bmp'
  ];
  
  static const List<String> supportedDocumentTypes = [
    'pdf', 'docx', 'txt', 'rtf'
  ];
  
  // OCR confidence thresholds
  static const double highConfidenceThreshold = 0.8;
  static const double mediumConfidenceThreshold = 0.6;
  static const double lowConfidenceThreshold = 0.4;
  
  // Question generation defaults
  static const int defaultQuestionCount = 10;
  static const List<String> questionTypes = [
    'MCQ', 'Short Answer', 'Long Answer', 'True/False'
  ];
  
  // Compression profiles
  static const Map<String, int> compressionProfiles = {
    'WhatsApp': 1,
    'Email': 5,
    'College Portal': 10,
    'High Quality': 25,
  };
}

class AppStrings {
  // Dashboard
  static const String dashboardTitle = 'AI Document Master';
  static const String recentDocuments = 'Recent Documents';
  static const String quickActions = 'Quick Actions';
  
  // Upload
  static const String uploadTitle = 'Upload Document';
  static const String selectFile = 'Select File';
  static const String captureImage = 'Capture Image';
  static const String chooseProfile = 'Choose Compression Profile';
  
  // Processing
  static const String processing = 'Processing...';
  static const String ocrProcessing = 'OCR Processing';
  static const String handwritingRecognition = 'Handwriting Recognition';
  static const String generatingQuestions = 'Generating Questions';
  
  // Success/Error
  static const String uploadSuccess = 'Document uploaded successfully!';
  static const String processingComplete = 'Processing complete!';
  static const String errorOccurred = 'An error occurred';
}
