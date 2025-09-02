import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/image_processing_service.dart';
import '../providers/app_provider.dart';
import '../widgets/image_cropper_widget.dart';
import '../widgets/compression_slider.dart';
import '../widgets/enhancement_controls.dart';

class ImageEditorScreen extends StatefulWidget {
  final File? initialImage;
  final List<ProcessingTask>? initialTasks;

  const ImageEditorScreen({
    Key? key,
    this.initialImage,
    this.initialTasks,
  }) : super(key: key);

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen>
    with TickerProviderStateMixin {
  File? _currentImage;
  File? _originalImage;
  List<ProcessingTask> _tasks = [];
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String? _processingStatus;
  String? _extractedText;
  bool _showTextResult = false;

  // Controllers
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Processing options
  int _compressionQuality = 85;
  int _maxFileSizeKB = 1000;
  double _brightness = 0.0;
  double _contrast = 1.0;
  CropShape _cropShape = CropShape.rectangle;
  Rect? _cropArea;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    if (widget.initialImage != null) {
      _currentImage = widget.initialImage;
      _originalImage = widget.initialImage;
    }
    
    if (widget.initialTasks != null) {
      _tasks = List.from(widget.initialTasks!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🖼️ Image Editor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_currentImage != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetImage,
              tooltip: 'Reset to original',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveImage,
              tooltip: 'Save processed image',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.crop), text: 'Crop'),
            Tab(icon: Icon(Icons.compress), text: 'Compress'),
            Tab(icon: Icon(Icons.auto_fix_high), text: 'Enhance'),
            Tab(icon: Icon(Icons.text_fields), text: 'OCR'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Image Preview Section
          Expanded(
            flex: 2,
            child: _buildImagePreview(),
          ),
          
          // Processing Progress
          if (_isProcessing) _buildProcessingProgress(),
          
          // OCR Text Result
          if (_showTextResult && _extractedText != null) _buildTextResult(),
          
          // Tools Section
          Expanded(
            flex: 1,
            child: _buildToolsSection(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildImagePreview() {
    if (_currentImage == null) {
      return _buildImagePlaceholder();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.file(
                _currentImage!,
                fit: BoxFit.contain,
              ),
            ),
            
            // Crop overlay
            if (_tabController.index == 0 && _cropArea != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(_cropArea!),
                ),
              ),
            
            // Processing overlay
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select an image to edit',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(value: _processingProgress),
          const SizedBox(height: 8),
          Text(
            _processingStatus ?? 'Processing...',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTextResult() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📝 Extracted Text',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showTextResult = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _extractedText!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyText(_extractedText!),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareText(_extractedText!),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCropTab(),
        _buildCompressTab(),
        _buildEnhanceTab(),
        _buildOCRTab(),
      ],
    );
  }

  Widget _buildCropTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crop & Resize',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Aspect ratio options
          const Text('Aspect Ratio:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildAspectRatioChip('Free', null),
              _buildAspectRatioChip('1:1', 1.0),
              _buildAspectRatioChip('4:3', 4/3),
              _buildAspectRatioChip('16:9', 16/9),
              _buildAspectRatioChip('A4', 1.414),
            ],
          ),
          const SizedBox(height: 16),
          
          // Crop shape
          const Text('Crop Shape:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildShapeChip('Rectangle', CropShape.rectangle),
              _buildShapeChip('Circle', CropShape.circle),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _autoCrop,
                  icon: const Icon(Icons.crop_free),
                  label: const Text('Auto Crop'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _manualCrop,
                  icon: const Icon(Icons.crop_square),
                  label: const Text('Manual Crop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compression & Size',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Quality slider
          Text('Quality: ${_compressionQuality}%'),
          Slider(
            value: _compressionQuality.toDouble(),
            min: 10,
            max: 100,
            divisions: 18,
            onChanged: (value) {
              setState(() {
                _compressionQuality = value.round();
              });
            },
          ),
          const SizedBox(height: 16),
          
          // File size slider
          Text('Max File Size: ${_maxFileSizeKB}KB'),
          Slider(
            value: _maxFileSizeKB.toDouble(),
            min: 50,
            max: 5000,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _maxFileSizeKB = value.round();
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Compression buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _compressImage,
                  icon: const Icon(Icons.compress),
                  label: const Text('Compress'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _smartCompress,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Smart Compress'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image Enhancement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Brightness slider
          Text('Brightness: ${_brightness.toStringAsFixed(1)}'),
          Slider(
            value: _brightness,
            min: -1.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _brightness = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Contrast slider
          Text('Contrast: ${_contrast.toStringAsFixed(1)}'),
          Slider(
            value: _contrast,
            min: 0.0,
            max: 3.0,
            divisions: 30,
            onChanged: (value) {
              setState(() {
                _contrast = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Enhancement buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _autoEnhance,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto Enhance'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _adjustBrightnessContrast,
                  icon: const Icon(Icons.tune),
                  label: const Text('Apply'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Additional enhancements
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reduceNoise,
                  icon: const Icon(Icons.blur_on),
                  label: const Text('Reduce Noise'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sharpenImage,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Sharpen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOCRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Extraction (OCR)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Language selection
          const Text('Languages:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildLanguageChip('Auto', 'auto'),
              _buildLanguageChip('English', 'en'),
              _buildLanguageChip('Hindi', 'hi'),
              _buildLanguageChip('Bengali', 'bn'),
              _buildLanguageChip('Tamil', 'ta'),
            ],
          ),
          const SizedBox(height: 16),
          
          // OCR options
          const Text('Options:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _extractText,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Extract Text'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _recognizeHandwriting,
                  icon: const Icon(Icons.draw),
                  label: const Text('Handwriting'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Multi-language OCR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _extractMultiLanguage,
              icon: const Icon(Icons.language),
              label: const Text('Multi-Language OCR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentImage == null) {
      return FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add_a_photo),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _processAllTasks,
      label: const Text('Process All'),
      icon: const Icon(Icons.play_arrow),
    );
  }

  // Helper widgets
  Widget _buildAspectRatioChip(String label, double? ratio) {
    return FilterChip(
      label: Text(label),
      selected: _cropArea == null && ratio == null,
      onSelected: (selected) {
        setState(() {
          _cropArea = null;
        });
        if (ratio != null) {
          _cropWithAspectRatio(ratio);
        }
      },
    );
  }

  Widget _buildShapeChip(String label, CropShape shape) {
    return FilterChip(
      label: Text(label),
      selected: _cropShape == shape,
      onSelected: (selected) {
        setState(() {
          _cropShape = shape;
        });
      },
    );
  }

  Widget _buildLanguageChip(String label, String code) {
    return FilterChip(
      label: Text(label),
      selected: true, // For now, all languages are selected
      onSelected: (selected) {
        // Handle language selection
      },
    );
  }

  // Action methods
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _currentImage = File(image.path);
        _originalImage = File(image.path);
        _extractedText = null;
        _showTextResult = false;
      });
    }
  }

  void _resetImage() {
    setState(() {
      _currentImage = _originalImage;
      _tasks.clear();
      _extractedText = null;
      _showTextResult = false;
    });
  }

  Future<void> _saveImage() async {
    if (_currentImage == null) return;
    
    // Save to gallery or documents
    // Implementation depends on platform
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image saved successfully!')),
    );
  }

  // Processing methods
  Future<void> _autoCrop() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Auto-cropping image...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final croppedImage = await imageService.autoCrop(_currentImage!);
      
      setState(() {
        _currentImage = croppedImage;
        _tasks.add(ProcessingTask(type: ProcessingType.crop));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Auto-crop failed: $e');
    }
  }

  Future<void> _manualCrop() async {
    // Show crop overlay for manual selection
    // Implementation depends on crop widget
  }

  Future<void> _cropWithAspectRatio(double ratio) async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Cropping with aspect ratio...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final croppedImage = await imageService.cropWithAspectRatio(
        imageFile: _currentImage!,
        aspectRatio: ratio,
      );
      
      setState(() {
        _currentImage = croppedImage;
        _tasks.add(ProcessingTask(type: ProcessingType.crop));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Aspect ratio cropping failed: $e');
    }
  }

  Future<void> _compressImage() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Compressing image...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final compressedImage = await imageService.compressImage(
        imageFile: _currentImage!,
        quality: _compressionQuality,
        maxFileSizeKB: _maxFileSizeKB,
      );
      
      setState(() {
        _currentImage = compressedImage;
        _tasks.add(ProcessingTask(
          type: ProcessingType.compress,
          parameters: {
            'quality': _compressionQuality,
            'maxFileSizeKB': _maxFileSizeKB,
          },
        ));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Compression failed: $e');
    }
  }

  Future<void> _smartCompress() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Smart compressing...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final compressedImage = await imageService.smartCompress(
        _currentImage!,
        _maxFileSizeKB,
      );
      
      setState(() {
        _currentImage = compressedImage;
        _tasks.add(ProcessingTask(
          type: ProcessingType.compress,
          parameters: {'maxFileSizeKB': _maxFileSizeKB},
        ));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Smart compression failed: $e');
    }
  }

  Future<void> _autoEnhance() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Auto-enhancing image...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final enhancedImage = await imageService.autoEnhance(_currentImage!);
      
      setState(() {
        _currentImage = enhancedImage;
        _tasks.add(ProcessingTask(type: ProcessingType.enhance));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Auto-enhancement failed: $e');
    }
  }

  Future<void> _adjustBrightnessContrast() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Adjusting brightness and contrast...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final adjustedImage = await imageService.adjustBrightnessContrast(
        imageFile: _currentImage!,
        brightness: _brightness,
        contrast: _contrast,
      );
      
      setState(() {
        _currentImage = adjustedImage;
        _tasks.add(ProcessingTask(
          type: ProcessingType.enhance,
          parameters: {
            'brightness': _brightness,
            'contrast': _contrast,
          },
        ));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Brightness/contrast adjustment failed: $e');
    }
  }

  Future<void> _reduceNoise() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Reducing noise...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final denoisedImage = await imageService.reduceNoise(_currentImage!);
      
      setState(() {
        _currentImage = denoisedImage;
        _tasks.add(ProcessingTask(type: ProcessingType.enhance));
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Noise reduction failed: $e');
    }
  }

  Future<void> _sharpenImage() async {
    // Implementation for image sharpening
    _showError('Sharpening feature coming soon!');
  }

  Future<void> _extractText() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Extracting text...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final text = await imageService.extractText(_currentImage!);
      
      setState(() {
        _extractedText = text;
        _showTextResult = true;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Text extraction failed: $e');
    }
  }

  Future<void> _recognizeHandwriting() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Recognizing handwriting...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final text = await imageService.recognizeHandwriting(_currentImage!);
      
      setState(() {
        _extractedText = text;
        _showTextResult = true;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Handwriting recognition failed: $e');
    }
  }

  Future<void> _extractMultiLanguage() async {
    if (_currentImage == null) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Extracting text in multiple languages...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final results = await imageService.extractMultiLanguage(
        imageFile: _currentImage!,
        languages: ['en', 'hi', 'bn', 'ta'],
      );
      
      final allText = results.values.join('\n\n---\n\n');
      
      setState(() {
        _extractedText = allText;
        _showTextResult = true;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Multi-language OCR failed: $e');
    }
  }

  Future<void> _processAllTasks() async {
    if (_currentImage == null || _tasks.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Processing all tasks...';
    });

    try {
      final imageService = context.read<AppProvider>().imageProcessingService;
      final results = await imageService.processBatch(
        images: [_originalImage!],
        tasks: _tasks,
        onProgress: (current, total) {
          setState(() {
            _processingProgress = current / total;
          });
        },
      );
      
      if (results.isNotEmpty && results.first.success) {
        setState(() {
          _currentImage = results.first.processedFile;
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All tasks completed successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Batch processing failed: $e');
    }
  }

  void _copyText(String text) {
    // Implementation for copying text to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard!')),
    );
  }

  void _shareText(String text) {
    // Implementation for sharing text
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing text...')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Custom painter for crop overlay
class CropOverlayPainter extends CustomPainter {
  final Rect cropArea;

  CropOverlayPainter(this.cropArea);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromLTWH(
      cropArea.left,
      cropArea.top,
      cropArea.width,
      cropArea.height,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
