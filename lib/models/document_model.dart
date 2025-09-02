enum DocumentStatus {
  uploaded,
  processing,
  ocrCompleted,
  handwritingRecognitionCompleted,
  completed,
  failed,
}

enum DocumentType {
  image,
  pdf,
  word,
  text,
  handwritten,
  mixed,
}

class Document {
  final String id;
  final String userId;
  final String? organizationId;
  final String fileName;
  final String originalFileUrl;
  final String? processedFileUrl;
  final DocumentType type;
  final DocumentStatus status;
  final String? language;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final List<DocumentPage>? pages;
  final double? processingProgress;
  final String? errorMessage;

  Document({
    required this.id,
    required this.userId,
    this.organizationId,
    required this.fileName,
    required this.originalFileUrl,
    this.processedFileUrl,
    required this.type,
    required this.status,
    this.language,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.pages,
    this.processingProgress,
    this.errorMessage,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      userId: json['user_id'],
      organizationId: json['organization_id'],
      fileName: json['file_name'],
      originalFileUrl: json['original_file_url'],
      processedFileUrl: json['processed_file_url'],
      type: DocumentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DocumentType.image,
      ),
      status: DocumentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DocumentStatus.uploaded,
      ),
      language: json['language'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      metadata: json['metadata'],
      pages: json['pages'] != null 
          ? (json['pages'] as List)
              .map((page) => DocumentPage.fromJson(page))
              .toList()
          : null,
      processingProgress: json['processing_progress']?.toDouble(),
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'organization_id': organizationId,
      'file_name': fileName,
      'original_file_url': originalFileUrl,
      'processed_file_url': processedFileUrl,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'pages': pages?.map((page) => page.toJson()).toList(),
      'processing_progress': processingProgress,
      'error_message': errorMessage,
    };
  }

  Document copyWith({
    String? id,
    String? userId,
    String? organizationId,
    String? fileName,
    String? originalFileUrl,
    String? processedFileUrl,
    DocumentType? type,
    DocumentStatus? status,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<DocumentPage>? pages,
    double? processingProgress,
    String? errorMessage,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      fileName: fileName ?? this.fileName,
      originalFileUrl: originalFileUrl ?? this.originalFileUrl,
      processedFileUrl: processedFileUrl ?? this.processedFileUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      pages: pages ?? this.pages,
      processingProgress: processingProgress ?? this.processingProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isProcessing => status == DocumentStatus.processing;
  bool get isCompleted => status == DocumentStatus.completed;
  bool get hasFailed => status == DocumentStatus.failed;
  bool get canEdit => status == DocumentStatus.completed;
  
  String get statusDisplayText {
    switch (status) {
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.processing:
        return 'Processing...';
      case DocumentStatus.ocrCompleted:
        return 'OCR Completed';
      case DocumentStatus.handwritingRecognitionCompleted:
        return 'Handwriting Recognition Completed';
      case DocumentStatus.completed:
        return 'Completed';
      case DocumentStatus.failed:
        return 'Failed';
    }
  }

  String get typeDisplayText {
    switch (type) {
      case DocumentType.image:
        return 'Image';
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.word:
        return 'Word Document';
      case DocumentType.text:
        return 'Text';
      case DocumentType.handwritten:
        return 'Handwritten';
      case DocumentType.mixed:
        return 'Mixed';
    }
  }
}

class DocumentPage {
  final String id;
  final String documentId;
  final int pageNumber;
  final String imageUrl;
  final String? ocrText;
  final Map<String, double>? ocrConfidence;
  final String? handwritingText;
  final Map<String, double>? handwritingConfidence;
  final Map<String, dynamic>? layoutAnalysis;
  final DateTime createdAt;

  DocumentPage({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.imageUrl,
    this.ocrText,
    this.ocrConfidence,
    this.handwritingText,
    this.handwritingConfidence,
    this.layoutAnalysis,
    required this.createdAt,
  });

  factory DocumentPage.fromJson(Map<String, dynamic> json) {
    return DocumentPage(
      id: json['id'],
      documentId: json['document_id'],
      pageNumber: json['page_number'],
      imageUrl: json['image_url'],
      ocrText: json['ocr_text'],
      ocrConfidence: json['ocr_confidence'] != null 
          ? Map<String, double>.from(json['ocr_confidence'])
          : null,
      handwritingText: json['handwriting_text'],
      handwritingConfidence: json['handwriting_confidence'] != null 
          ? Map<String, double>.from(json['handwriting_confidence'])
          : null,
      layoutAnalysis: json['layout_analysis'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'image_url': imageUrl,
      'ocr_text': ocrText,
      'ocr_confidence': ocrConfidence,
      'handwriting_text': handwritingText,
      'handwriting_confidence': handwritingConfidence,
      'layout_analysis': layoutAnalysis,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get averageOcrConfidence {
    if (ocrConfidence == null || ocrConfidence!.isEmpty) return 0.0;
    return ocrConfidence!.values.reduce((a, b) => a + b) / ocrConfidence!.length;
  }

  double get averageHandwritingConfidence {
    if (handwritingConfidence == null || handwritingConfidence!.isEmpty) return 0.0;
    return handwritingConfidence!.values.reduce((a, b) => a + b) / handwritingConfidence!.length;
  }

  String get finalText => handwritingText ?? ocrText ?? '';
  
  bool get hasLowConfidence {
    return averageOcrConfidence < 0.6 || averageHandwritingConfidence < 0.6;
  }
}
