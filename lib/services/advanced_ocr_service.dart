import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class AdvancedOCRService {
  final ApiClient _apiClient;
  final Uuid _uuid = Uuid();

  AdvancedOCRService(this._apiClient);

  // ==================== BASIC OCR ====================
  
  /// Extract text from image with language detection
  Future<OCRResult> extractText({
    required File imageFile,
    String? language,
    bool enhanceImage = true,
    OCRMode mode = OCRMode.standard,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/extract',
        imageFile.path,
        fields: {
          'language': language ?? 'auto',
          'enhance': enhanceImage.toString(),
          'mode': mode.name,
        },
        onProgress: (progress) {
          // Handle progress updates
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OCRResult.fromJson(data);
      } else {
        throw Exception('OCR extraction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OCR extraction failed: $e');
    }
  }

  // ==================== MULTI-LANGUAGE OCR ====================
  
  /// Extract text in multiple languages simultaneously
  Future<MultiLanguageOCRResult> extractMultiLanguage({
    required File imageFile,
    List<String> languages = const ['en', 'hi', 'bn', 'ta', 'te', 'mr', 'gu', 'kn'],
    bool detectLanguage = true,
    OCRMode mode = OCRMode.standard,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/multi-language',
        imageFile.path,
        fields: {
          'languages': languages.join(','),
          'detect_language': detectLanguage.toString(),
          'mode': mode.name,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MultiLanguageOCRResult.fromJson(data);
      } else {
        throw Exception('Multi-language OCR failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Multi-language OCR failed: $e');
    }
  }

  // ==================== HANDWRITING RECOGNITION ====================
  
  /// Recognize handwritten text
  Future<HandwritingResult> recognizeHandwriting({
    required File imageFile,
    String? language,
    bool enhanceImage = true,
    HandwritingStyle style = HandwritingStyle.auto,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/handwriting',
        imageFile.path,
        fields: {
          'language': language ?? 'auto',
          'enhance': enhanceImage.toString(),
          'style': style.name,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HandwritingResult.fromJson(data);
      } else {
        throw Exception('Handwriting recognition failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Handwriting recognition failed: $e');
    }
  }

  // ==================== TABLE EXTRACTION ====================
  
  /// Extract table data from image
  Future<TableResult> extractTable({
    required File imageFile,
    String? language,
    TableFormat format = TableFormat.csv,
    bool detectHeaders = true,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/table',
        imageFile.path,
        fields: {
          'language': language ?? 'auto',
          'format': format.name,
          'detect_headers': detectHeaders.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TableResult.fromJson(data);
      } else {
        throw Exception('Table extraction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Table extraction failed: $e');
    }
  }

  // ==================== FORM PROCESSING ====================
  
  /// Extract form fields and data
  Future<FormResult> extractFormFields({
    required File imageFile,
    String? formTemplate,
    List<String>? expectedFields,
    bool validateData = true,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/form',
        imageFile.path,
        fields: {
          'form_template': formTemplate ?? '',
          'expected_fields': expectedFields?.join(',') ?? '',
          'validate_data': validateData.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FormResult.fromJson(data);
      } else {
        throw Exception('Form extraction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Form extraction failed: $e');
    }
  }

  // ==================== DOCUMENT ANALYSIS ====================
  
  /// Analyze document structure and content
  Future<DocumentAnalysisResult> analyzeDocument({
    required File imageFile,
    List<DocumentSection> sections = const [],
    bool extractMetadata = true,
    bool detectLayout = true,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/analyze',
        imageFile.path,
        fields: {
          'sections': sections.map((s) => s.name).join(','),
          'extract_metadata': extractMetadata.toString(),
          'detect_layout': detectLayout.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DocumentAnalysisResult.fromJson(data);
      } else {
        throw Exception('Document analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Document analysis failed: $e');
    }
  }

  // ==================== BATCH OCR PROCESSING ====================
  
  /// Process multiple images with OCR
  Future<List<OCRResult>> processBatch({
    required List<File> images,
    required OCRBatchOptions options,
    Function(int, double)? onProgress,
  }) async {
    final List<OCRResult> results = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final result = await extractText(
          imageFile: images[i],
          language: options.language,
          enhanceImage: options.enhanceImage,
          mode: options.mode,
        );
        results.add(result);
        
        onProgress?.call(i + 1, (i + 1) / images.length);
      } catch (e) {
        results.add(OCRResult(
          text: '',
          confidence: 0.0,
          language: options.language ?? 'unknown',
          success: false,
          error: e.toString(),
        ));
      }
    }
    
    return results;
  }

  // ==================== OCR ENHANCEMENT ====================
  
  /// Enhance image for better OCR results
  Future<File> enhanceForOCR({
    required File imageFile,
    List<EnhancementType> enhancements = const [
      EnhancementType.denoise,
      EnhancementType.sharpen,
      EnhancementType.contrast,
    ],
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/enhance',
        imageFile.path,
        fields: {
          'enhancements': enhancements.map((e) => e.name).join(','),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final enhancedPath = data['enhanced_image_path'];
        
        if (enhancedPath != null) {
          return File(enhancedPath);
        } else {
          throw Exception('Enhanced image path not found in response');
        }
      } else {
        throw Exception('Image enhancement failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Image enhancement failed: $e');
    }
  }

  // ==================== OCR VALIDATION ====================
  
  /// Validate OCR results
  Future<OCRValidationResult> validateOCR({
    required String extractedText,
    String? expectedText,
    List<String>? keywords,
    double minConfidence = 0.8,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/ocr/validate',
        body: {
          'extracted_text': extractedText,
          'expected_text': expectedText,
          'keywords': keywords,
          'min_confidence': minConfidence,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OCRValidationResult.fromJson(data);
      } else {
        throw Exception('OCR validation failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OCR validation failed: $e');
    }
  }

  // ==================== EXPORT FUNCTIONS ====================
  
  /// Export OCR results to different formats
  Future<File> exportResults({
    required OCRResult result,
    ExportFormat format = ExportFormat.txt,
    String? outputPath,
  }) async {
    try {
      String content = '';
      String extension = '';
      
      switch (format) {
        case ExportFormat.txt:
          content = result.text;
          extension = 'txt';
          break;
        case ExportFormat.json:
          content = json.encode(result.toJson());
          extension = 'json';
          break;
        case ExportFormat.csv:
          content = _convertToCSV(result);
          extension = 'csv';
          break;
        case ExportFormat.pdf:
          // PDF generation would require additional packages
          throw Exception('PDF export not implemented yet');
      }
      
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ocr_result_${_uuid.v4()}.$extension';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsString(content);
      return file;
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  String _convertToCSV(OCRResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Text,Confidence,Language,Success');
    buffer.writeln('"${result.text.replaceAll('"', '""')}",${result.confidence},${result.language},${result.success}');
    return buffer.toString();
  }
}

// ==================== ENUMS ====================

enum OCRMode { standard, fast, accurate, handwritten }

enum HandwritingStyle { cursive, printed, mixed, auto }

enum TableFormat { csv, json, excel, html }

enum DocumentSection { header, footer, body, sidebar, table, image }

enum EnhancementType { denoise, sharpen, contrast, brightness, rotation }

enum ExportFormat { txt, json, csv, pdf }

// ==================== MODELS ====================

class OCRResult {
  final String text;
  final double confidence;
  final String language;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;
  final List<TextBlock>? textBlocks;
  final ProcessingTime? processingTime;

  OCRResult({
    required this.text,
    required this.confidence,
    required this.language,
    required this.success,
    this.error,
    this.metadata,
    this.textBlocks,
    this.processingTime,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      language: json['language'] ?? 'unknown',
      success: json['success'] ?? false,
      error: json['error'],
      metadata: json['metadata'],
      textBlocks: json['text_blocks'] != null
          ? (json['text_blocks'] as List)
              .map((b) => TextBlock.fromJson(b))
              .toList()
          : null,
      processingTime: json['processing_time'] != null
          ? ProcessingTime.fromJson(json['processing_time'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'confidence': confidence,
      'language': language,
      'success': success,
      'error': error,
      'metadata': metadata,
      'text_blocks': textBlocks?.map((b) => b.toJson()).toList(),
      'processing_time': processingTime?.toJson(),
    };
  }
}

class MultiLanguageOCRResult {
  final Map<String, OCRResult> results;
  final String detectedLanguage;
  final double overallConfidence;
  final bool success;
  final String? error;

  MultiLanguageOCRResult({
    required this.results,
    required this.detectedLanguage,
    required this.overallConfidence,
    required this.success,
    this.error,
  });

  factory MultiLanguageOCRResult.fromJson(Map<String, dynamic> json) {
    final resultsMap = <String, OCRResult>{};
    if (json['results'] != null) {
      (json['results'] as Map<String, dynamic>).forEach((key, value) {
        resultsMap[key] = OCRResult.fromJson(value);
      });
    }

    return MultiLanguageOCRResult(
      results: resultsMap,
      detectedLanguage: json['detected_language'] ?? 'unknown',
      overallConfidence: (json['overall_confidence'] ?? 0.0).toDouble(),
      success: json['success'] ?? false,
      error: json['error'],
    );
  }
}

class HandwritingResult extends OCRResult {
  final HandwritingStyle style;
  final double handwritingConfidence;
  final List<HandwritingSegment>? segments;

  HandwritingResult({
    required super.text,
    required super.confidence,
    required super.language,
    required super.success,
    required this.style,
    required this.handwritingConfidence,
    this.segments,
    super.error,
    super.metadata,
    super.textBlocks,
    super.processingTime,
  });

  factory HandwritingResult.fromJson(Map<String, dynamic> json) {
    return HandwritingResult(
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      language: json['language'] ?? 'unknown',
      success: json['success'] ?? false,
      style: HandwritingStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => HandwritingStyle.auto,
      ),
      handwritingConfidence: (json['handwriting_confidence'] ?? 0.0).toDouble(),
      segments: json['segments'] != null
          ? (json['segments'] as List)
              .map((s) => HandwritingSegment.fromJson(s))
              .toList()
          : null,
      error: json['error'],
      metadata: json['metadata'],
      textBlocks: json['text_blocks'] != null
          ? (json['text_blocks'] as List)
              .map((b) => TextBlock.fromJson(b))
              .toList()
          : null,
      processingTime: json['processing_time'] != null
          ? ProcessingTime.fromJson(json['processing_time'])
          : null,
    );
  }
}

class TableResult {
  final List<List<String>> data;
  final List<String>? headers;
  final String? language;
  final double confidence;
  final bool success;
  final String? error;
  final TableFormat format;

  TableResult({
    required this.data,
    this.headers,
    this.language,
    required this.confidence,
    required this.success,
    this.error,
    required this.format,
  });

  factory TableResult.fromJson(Map<String, dynamic> json) {
    return TableResult(
      data: json['data'] != null
          ? (json['data'] as List)
              .map((row) => (row as List).cast<String>())
              .toList()
          : [],
      headers: json['headers'] != null
          ? (json['headers'] as List).cast<String>()
          : null,
      language: json['language'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      success: json['success'] ?? false,
      error: json['error'],
      format: TableFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => TableFormat.csv,
      ),
    );
  }
}

class FormResult {
  final Map<String, FormField> fields;
  final String? formType;
  final double confidence;
  final bool success;
  final String? error;
  final List<ValidationError>? validationErrors;

  FormResult({
    required this.fields,
    this.formType,
    required this.confidence,
    required this.success,
    this.error,
    this.validationErrors,
  });

  factory FormResult.fromJson(Map<String, dynamic> json) {
    final fieldsMap = <String, FormField>{};
    if (json['fields'] != null) {
      (json['fields'] as Map<String, dynamic>).forEach((key, value) {
        fieldsMap[key] = FormField.fromJson(value);
      });
    }

    return FormResult(
      fields: fieldsMap,
      formType: json['form_type'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      success: json['success'] ?? false,
      error: json['error'],
      validationErrors: json['validation_errors'] != null
          ? (json['validation_errors'] as List)
              .map((e) => ValidationError.fromJson(e))
              .toList()
          : null,
    );
  }
}

class DocumentAnalysisResult {
  final List<DocumentSection> sections;
  final Map<String, dynamic> metadata;
  final DocumentLayout layout;
  final double confidence;
  final bool success;
  final String? error;

  DocumentAnalysisResult({
    required this.sections,
    required this.metadata,
    required this.layout,
    required this.confidence,
    required this.success,
    this.error,
  });

  factory DocumentAnalysisResult.fromJson(Map<String, dynamic> json) {
    return DocumentAnalysisResult(
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((s) => DocumentSection.values.firstWhere(
                    (e) => e.name == s,
                    orElse: () => DocumentSection.body,
                  ))
              .toList()
          : [],
      metadata: json['metadata'] ?? {},
      layout: DocumentLayout.fromJson(json['layout'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      success: json['success'] ?? false,
      error: json['error'],
    );
  }
}

// ==================== SUPPORTING MODELS ====================

class TextBlock {
  final String text;
  final Rect bounds;
  final double confidence;
  final String? language;

  TextBlock({
    required this.text,
    required this.bounds,
    required this.confidence,
    this.language,
  });

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      text: json['text'] ?? '',
      bounds: Rect.fromJson(json['bounds'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'bounds': bounds.toJson(),
      'confidence': confidence,
      'language': language,
    };
  }
}

class HandwritingSegment {
  final String text;
  final Rect bounds;
  final double confidence;
  final HandwritingStyle style;

  HandwritingSegment({
    required this.text,
    required this.bounds,
    required this.confidence,
    required this.style,
  });

  factory HandwritingSegment.fromJson(Map<String, dynamic> json) {
    return HandwritingSegment(
      text: json['text'] ?? '',
      bounds: Rect.fromJson(json['bounds'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      style: HandwritingStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => HandwritingStyle.auto,
      ),
    );
  }
}

class FormField {
  final String name;
  final String value;
  final String type;
  final Rect bounds;
  final double confidence;
  final bool required;
  final List<String>? validationRules;

  FormField({
    required this.name,
    required this.value,
    required this.type,
    required this.bounds,
    required this.confidence,
    required this.required,
    this.validationRules,
  });

  factory FormField.fromJson(Map<String, dynamic> json) {
    return FormField(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      type: json['type'] ?? '',
      bounds: Rect.fromJson(json['bounds'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      required: json['required'] ?? false,
      validationRules: json['validation_rules'] != null
          ? (json['validation_rules'] as List).cast<String>()
          : null,
    );
  }
}

class ValidationError {
  final String field;
  final String message;
  final String rule;
  final double confidence;

  ValidationError({
    required this.field,
    required this.message,
    required this.rule,
    required this.confidence,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      rule: json['rule'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class DocumentLayout {
  final int columns;
  final int rows;
  final List<LayoutRegion> regions;
  final String orientation;

  DocumentLayout({
    required this.columns,
    required this.rows,
    required this.regions,
    required this.orientation,
  });

  factory DocumentLayout.fromJson(Map<String, dynamic> json) {
    return DocumentLayout(
      columns: json['columns'] ?? 1,
      rows: json['rows'] ?? 1,
      regions: json['regions'] != null
          ? (json['regions'] as List)
              .map((r) => LayoutRegion.fromJson(r))
              .toList()
          : [],
      orientation: json['orientation'] ?? 'portrait',
    );
  }
}

class LayoutRegion {
  final String type;
  final Rect bounds;
  final double confidence;

  LayoutRegion({
    required this.type,
    required this.bounds,
    required this.confidence,
  });

  factory LayoutRegion.fromJson(Map<String, dynamic> json) {
    return LayoutRegion(
      type: json['type'] ?? '',
      bounds: Rect.fromJson(json['bounds'] ?? {}),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class ProcessingTime {
  final int totalMs;
  final int preprocessingMs;
  final int ocrMs;
  final int postprocessingMs;

  ProcessingTime({
    required this.totalMs,
    required this.preprocessingMs,
    required this.ocrMs,
    required this.postprocessingMs,
  });

  factory ProcessingTime.fromJson(Map<String, dynamic> json) {
    return ProcessingTime(
      totalMs: json['total_ms'] ?? 0,
      preprocessingMs: json['preprocessing_ms'] ?? 0,
      ocrMs: json['ocr_ms'] ?? 0,
      postprocessingMs: json['postprocessing_ms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_ms': totalMs,
      'preprocessing_ms': preprocessingMs,
      'ocr_ms': ocrMs,
      'postprocessing_ms': postprocessingMs,
    };
  }
}

class OCRValidationResult {
  final bool isValid;
  final double accuracy;
  final List<String> suggestions;
  final List<String> corrections;
  final double confidence;

  OCRValidationResult({
    required this.isValid,
    required this.accuracy,
    required this.suggestions,
    required this.corrections,
    required this.confidence,
  });

  factory OCRValidationResult.fromJson(Map<String, dynamic> json) {
    return OCRValidationResult(
      isValid: json['is_valid'] ?? false,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      suggestions: json['suggestions'] != null
          ? (json['suggestions'] as List).cast<String>()
          : [],
      corrections: json['corrections'] != null
          ? (json['corrections'] as List).cast<String>()
          : [],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class OCRBatchOptions {
  final String? language;
  final bool enhanceImage;
  final OCRMode mode;
  final int maxConcurrent;
  final bool saveIntermediate;

  OCRBatchOptions({
    this.language,
    this.enhanceImage = true,
    this.mode = OCRMode.standard,
    this.maxConcurrent = 3,
    this.saveIntermediate = false,
  });
}

// ==================== RECT CLASS ====================

class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  factory Rect.fromJson(Map<String, dynamic> json) {
    return Rect(
      left: (json['left'] ?? 0.0).toDouble(),
      top: (json['top'] ?? 0.0).toDouble(),
      right: (json['right'] ?? 0.0).toDouble(),
      bottom: (json['bottom'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }
}
