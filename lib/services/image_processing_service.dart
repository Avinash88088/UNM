import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class ImageProcessingService {
  final ApiClient _apiClient;
  final Uuid _uuid = Uuid();

  ImageProcessingService(this._apiClient);

  // ==================== IMAGE COMPRESSION ====================
  
  /// Compress image with quality control
  Future<File> compressImage({
    required File imageFile,
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
    int? maxFileSizeKB,
  }) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Calculate new dimensions
      int newWidth = image.width;
      int newHeight = image.height;

      if (maxWidth != null && image.width > maxWidth) {
        newWidth = maxWidth;
        newHeight = (image.height * maxWidth / image.width).round();
      }

      if (maxHeight != null && newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (newWidth * maxHeight / newHeight).round();
      }

      // Resize image
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Compress with quality
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      // Check file size
      if (maxFileSizeKB != null && compressedBytes.length > maxFileSizeKB * 1024) {
        // Reduce quality until size is acceptable
        int currentQuality = quality;
        while (compressedBytes.length > maxFileSizeKB * 1024 && currentQuality > 10) {
          currentQuality -= 10;
          final newBytes = img.encodeJpg(resizedImage, quality: currentQuality);
          if (newBytes.length <= maxFileSizeKB * 1024) {
            return _saveCompressedImage(newBytes, imageFile.path);
          }
        }
      }

      return _saveCompressedImage(compressedBytes, imageFile.path);
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Smart compression based on target file size
  Future<File> smartCompress(File imageFile, int targetSizeKB) async {
    try {
      final originalSize = await imageFile.length();
      final targetSize = targetSizeKB * 1024;

      if (originalSize <= targetSize) {
        return imageFile; // No compression needed
      }

      // Start with high quality and reduce gradually
      int quality = 95;
      File? compressedFile;

      while (quality > 10) {
        compressedFile = await compressImage(
          imageFile: imageFile,
          quality: quality,
        );

        final compressedSize = await compressedFile!.length();
        if (compressedSize <= targetSize) {
          break;
        }

        quality -= 5;
      }

      return compressedFile ?? imageFile;
    } catch (e) {
      throw Exception('Smart compression failed: $e');
    }
  }

  /// Batch compress multiple images
  Future<List<File>> compressBatch({
    required List<File> images,
    int quality = 85,
    int? maxFileSizeKB,
    Function(int, double)? onProgress,
  }) async {
    final List<File> compressedImages = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final compressed = await compressImage(
          imageFile: images[i],
          quality: quality,
          maxFileSizeKB: maxFileSizeKB,
        );
        compressedImages.add(compressed);
        
        onProgress?.call(i + 1, (i + 1) / images.length);
      } catch (e) {
        // Skip failed images
        print('Failed to compress image ${i + 1}: $e');
      }
    }
    
    return compressedImages;
  }

  // ==================== IMAGE CROPPING ====================
  
  /// Crop image with custom area
  Future<File> cropImage({
    required File imageFile,
    required Rect cropArea,
    CropShape shape = CropShape.rectangle,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Validate crop area
      if (cropArea.left < 0 || cropArea.top < 0 ||
          cropArea.right > image.width || cropArea.bottom > image.height) {
        throw Exception('Invalid crop area');
      }

      // Crop image
      final croppedImage = img.copyCrop(
        image,
        x: cropArea.left.round(),
        y: cropArea.top.round(),
        width: cropArea.width.round(),
        height: cropArea.height.round(),
      );

      // Apply shape mask if needed
      if (shape == CropShape.circle) {
        // Create circular mask
        final maskedImage = _applyCircularMask(croppedImage);
        return _saveCroppedImage(maskedImage, imageFile.path);
      }

      return _saveCroppedImage(croppedImage, imageFile.path);
    } catch (e) {
      throw Exception('Image cropping failed: $e');
    }
  }

  /// Crop with specific aspect ratio
  Future<File> cropWithAspectRatio({
    required File imageFile,
    required double aspectRatio,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      int cropWidth = image.width;
      int cropHeight = image.height;

      if (aspectRatio > 1) {
        // Landscape
        cropHeight = (image.width / aspectRatio).round();
        if (cropHeight > image.height) {
          cropHeight = image.height;
          cropWidth = (image.height * aspectRatio).round();
        }
      } else {
        // Portrait
        cropWidth = (image.height * aspectRatio).round();
        if (cropWidth > image.width) {
          cropWidth = image.width;
          cropHeight = (image.width / aspectRatio).round();
        }
      }

      // Center the crop
      final x = (image.width - cropWidth) ~/ 2;
      final y = (image.height - cropHeight) ~/ 2;

      final croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: cropWidth,
        height: cropHeight,
      );

      return _saveCroppedImage(croppedImage, imageFile.path);
    } catch (e) {
      throw Exception('Aspect ratio cropping failed: $e');
    }
  }

  /// Auto-crop (remove borders)
  Future<File> autoCrop(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Find document boundaries
      final boundaries = _findDocumentBoundaries(image);
      
      final croppedImage = img.copyCrop(
        image,
        x: boundaries.left.toInt(),
        y: boundaries.top.toInt(),
        width: boundaries.width.toInt(),
        height: boundaries.height.toInt(),
      );

      return _saveCroppedImage(croppedImage, imageFile.path);
    } catch (e) {
      throw Exception('Auto-crop failed: $e');
    }
  }

  // ==================== IMAGE ENHANCEMENT ====================
  
  /// Auto-enhance image
  Future<File> autoEnhance(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Apply auto-enhancement
      final enhancedImage = img.adjustColor(
        image,
        brightness: 0.0,
        contrast: 1.2,
        saturation: 1.1,
      );
      
      return _saveEnhancedImage(enhancedImage, imageFile.path);
    } catch (e) {
      throw Exception('Auto-enhancement failed: $e');
    }
  }

  /// Adjust brightness and contrast
  Future<File> adjustBrightnessContrast({
    required File imageFile,
    double brightness = 0.0,
    double contrast = 1.0,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Apply brightness and contrast
      final adjustedImage = img.adjustColor(
        image,
        brightness: brightness,
        contrast: contrast,
      );

      return _saveEnhancedImage(adjustedImage, imageFile.path);
    } catch (e) {
      throw Exception('Brightness/contrast adjustment failed: $e');
    }
  }

  /// Reduce noise
  Future<File> reduceNoise(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Apply noise reduction
      final denoisedImage = img.gaussianBlur(image, radius: 1);

      return _saveEnhancedImage(denoisedImage, imageFile.path);
    } catch (e) {
      throw Exception('Noise reduction failed: $e');
    }
  }

  // ==================== OCR SERVICES ====================
  
  /// Extract text from image
  Future<String> extractText(File imageFile) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/extract',
        imageFile.path,
        fields: {'language': 'auto'},
        onProgress: (progress) {
          // Handle progress updates
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] ?? '';
      } else {
        throw Exception('OCR extraction failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OCR extraction failed: $e');
    }
  }

  /// Multi-language OCR
  Future<Map<String, String>> extractMultiLanguage({
    required File imageFile,
    List<String> languages = const ['en', 'hi', 'bn'],
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/multi-language',
        imageFile.path,
        fields: {'languages': languages.join(',')},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, String>.from(data['results'] ?? {});
      } else {
        throw Exception('Multi-language OCR failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Multi-language OCR failed: $e');
    }
  }

  /// Handwriting recognition
  Future<String> recognizeHandwriting(File imageFile) async {
    try {
      final response = await _apiClient.uploadFile(
        '/ai/ocr/handwriting',
        imageFile.path,
        fields: {'enhance': 'true'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] ?? '';
      } else {
        throw Exception('Handwriting recognition failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Handwriting recognition failed: $e');
    }
  }

  // ==================== BATCH PROCESSING ====================
  
  /// Process multiple images with different tasks
  Future<List<ProcessedImage>> processBatch({
    required List<File> images,
    required List<ProcessingTask> tasks,
    Function(int, double)? onProgress,
  }) async {
    final List<ProcessedImage> results = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final processed = await _processSingleImage(images[i], tasks);
        results.add(processed);
        
        onProgress?.call(i + 1, (i + 1) / images.length);
      } catch (e) {
        results.add(ProcessedImage(
          originalFile: images[i],
          processedFile: images[i],
          tasks: tasks,
          success: false,
          error: e.toString(),
        ));
      }
    }
    
    return results;
  }

  // ==================== UTILITY METHODS ====================
  
  Future<File> _saveCompressedImage(Uint8List bytes, String originalPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'compressed_${_uuid.v4()}.jpg';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> _saveCroppedImage(img.Image image, String originalPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'cropped_${_uuid.v4()}.jpg';
    final file = File('${tempDir.path}/$fileName');
    final bytes = img.encodeJpg(image);
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> _saveEnhancedImage(img.Image image, String originalPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'enhanced_${_uuid.v4()}.jpg';
    final file = File('${tempDir.path}/$fileName');
    final bytes = img.encodeJpg(image);
    await file.writeAsBytes(bytes);
    return file;
  }

  img.Image _applyCircularMask(img.Image image) {
    // Create circular mask
    final mask = img.Image.fromResized(image, width: image.width, height: image.height);
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    final radius = (image.width < image.height ? image.width : image.height) ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final distance = sqrt((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY));
        if (distance <= radius) {
          mask.setPixel(x, y, image.getPixel(x, y));
        }
      }
    }

    return mask;
  }

  Rect _findDocumentBoundaries(img.Image image) {
    // Simple edge detection for document boundaries
    // This is a basic implementation - can be enhanced with AI
    int minX = image.width, minY = image.height;
    int maxX = 0, maxY = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = p.r;
        final g = p.g;
        final b = p.b;
        final brightness = (r + g + b) / 3;
        
        if (brightness < 200) { // Dark pixel (document content)
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    return Rect(
      left: minX.toDouble(),
      top: minY.toDouble(),
      right: maxX.toDouble(),
      bottom: maxY.toDouble(),
    );
  }

  Future<ProcessedImage> _processSingleImage(File image, List<ProcessingTask> tasks) async {
    File currentImage = image;
    
    for (final task in tasks) {
      switch (task.type) {
        case ProcessingType.compress:
          currentImage = await compressImage(
            imageFile: currentImage,
            quality: task.parameters['quality'] ?? 85,
            maxFileSizeKB: task.parameters['maxFileSizeKB'],
          );
          break;
        case ProcessingType.crop:
          if (task.parameters['cropArea'] != null) {
            currentImage = await cropImage(
              imageFile: currentImage,
              cropArea: task.parameters['cropArea'],
              shape: task.parameters['shape'] ?? CropShape.rectangle,
            );
          }
          break;
        case ProcessingType.enhance:
          currentImage = await autoEnhance(currentImage);
          break;
        case ProcessingType.ocr:
          // OCR doesn't modify the image, just extracts text
          break;
      }
    }

    return ProcessedImage(
      originalFile: image,
      processedFile: currentImage,
      tasks: tasks,
      success: true,
    );
  }
}

// ==================== ENUMS & MODELS ====================

enum CropShape { rectangle, circle, custom }

enum ProcessingType { compress, crop, enhance, ocr }

class ProcessingTask {
  final ProcessingType type;
  final Map<String, dynamic> parameters;

  ProcessingTask({required this.type, this.parameters = const {}});
}

class ProcessedImage {
  final File originalFile;
  final File processedFile;
  final List<ProcessingTask> tasks;
  final bool success;
  final String? error;

  ProcessedImage({
    required this.originalFile,
    required this.processedFile,
    required this.tasks,
    required this.success,
    this.error,
  });
}

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
}
