import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/question_model.dart';
import 'document_results_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? selectedCompressionProfile;
  bool isUploading = false;
  double uploadProgress = 0.0;
  List<String> selectedFeatures = [];
  String? selectedLanguage;
  bool enableHandwritingRecognition = true;
  bool enableQuestionGeneration = false;
  File? selectedFile;
  String? selectedFileName;

  final List<String> languages = [
    'Auto-detect',
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.uploadTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadMethodsSection(),
            if (selectedFile != null) ...[
              const SizedBox(height: 16),
              _buildSelectedFileSection(),
            ],
            const SizedBox(height: 24),
            _buildCompressionProfileSection(),
            const SizedBox(height: 24),
            _buildProcessingOptionsSection(),
            const SizedBox(height: 24),
            _buildAdvancedOptionsSection(),
            const SizedBox(height: 32),
            _buildUploadButton(),
            if (isUploading) ...[
              const SizedBox(height: 24),
              _buildUploadProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Upload Method',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUploadMethodCard(
                title: AppStrings.selectFile,
                subtitle: 'From device storage',
                icon: Icons.folder_open,
                color: AppTheme.primaryColor,
                onTap: _selectFile,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUploadMethodCard(
                title: AppStrings.captureImage,
                subtitle: 'Take a photo',
                icon: Icons.camera_alt,
                color: AppTheme.secondaryColor,
                onTap: _captureImage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUploadMethodCard(
                title: 'Batch Upload',
                subtitle: 'Multiple files',
                icon: Icons.batch_prediction,
                color: AppTheme.accentColor,
                onTap: _batchUpload,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUploadMethodCard(
                title: 'From Cloud',
                subtitle: 'Drive, Dropbox, etc.',
                icon: Icons.cloud_upload,
                color: AppTheme.infoColor,
                onTap: _uploadFromCloud,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedFileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedFileName ?? 'Selected File',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for upload',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                selectedFile = null;
                selectedFileName = null;
              });
            },
            icon: const Icon(Icons.close),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompressionProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.chooseProfile,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppConstants.compressionProfiles.entries.map((entry) {
            final isSelected = selectedCompressionProfile == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCompressionProfile = entry.key;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${entry.key} (${entry.value}MB)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a compression profile based on your upload destination. Higher quality means larger file size.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Processing Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureToggle(
          title: 'OCR Processing',
          subtitle: 'Extract text from images and PDFs',
          icon: Icons.text_fields,
          color: AppTheme.primaryColor,
          isEnabled: true,
          onChanged: (value) {
            // OCR is always enabled
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureToggle(
          title: 'Handwriting Recognition',
          subtitle: 'Convert handwritten text to digital',
          icon: Icons.edit,
          color: AppTheme.secondaryColor,
          isEnabled: enableHandwritingRecognition,
          onChanged: (value) {
            setState(() {
              enableHandwritingRecognition = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureToggle(
          title: 'Question Generation',
          subtitle: 'Automatically create questions from content',
          icon: Icons.quiz,
          color: AppTheme.accentColor,
          isEnabled: enableQuestionGeneration,
          onChanged: (value) {
            setState(() {
              enableQuestionGeneration = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFeatureToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Options',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDropdownOption(
                  label: 'Language',
                  value: selectedLanguage ?? 'Auto-detect',
                  items: languages,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownOption(
                  label: 'Processing Priority',
                  value: 'Normal',
                  items: ['Low', 'Normal', 'High'],
                  onChanged: (value) {
                    if (value != null) {
                      // TODO: Handle priority selection
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownOption({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isUploading ? null : _startUpload,
        icon: isUploading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(isUploading ? Icons.upload : Icons.cloud_upload, size: 18),
        label: Text(isUploading ? 'Uploading...' : 'Start Processing'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Processing Document...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(uploadProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'This may take a few minutes depending on document size and complexity.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
          selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showErrorDialog('File selection failed: $e');
    }
  }

  void _captureImage() {
    // TODO: Implement camera capture
    _showFeatureComingSoon('Camera Capture');
  }

  void _batchUpload() {
    // TODO: Implement batch upload
    _showFeatureComingSoon('Batch Upload');
  }

  void _uploadFromCloud() {
    // TODO: Implement cloud upload
    _showFeatureComingSoon('Cloud Upload');
  }

  void _startUpload() async {
    if (selectedFile == null) {
      _showErrorDialog('Please select a file to upload');
      return;
    }

    if (selectedCompressionProfile == null) {
      _showErrorDialog('Please select a compression profile');
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Prepare features list
      final features = <String>['ocr'];
      if (enableHandwritingRecognition) features.add('hwr');
      if (enableQuestionGeneration) features.add('question_generation');

      // Upload document using backend service
      await appProvider.uploadDocument(
        filePath: selectedFile!.path,
        title: selectedFileName ?? 'Document',
        language: selectedLanguage,
        features: features,
        onProgress: (progress) {
          setState(() {
            uploadProgress = progress;
          });
        },
      );

      _uploadComplete();
    } catch (e) {
      _showErrorDialog('Upload failed: $e');
      setState(() {
        isUploading = false;
      });
    }
  }

  void _simulateUpload() {
    const uploadSteps = [
      {'step': 'Uploading file...', 'progress': 0.2},
      {'step': 'Processing image...', 'progress': 0.4},
      {'step': 'Running OCR...', 'progress': 0.6},
      {'step': 'Handwriting recognition...', 'progress': 0.8},
      {'step': 'Finalizing...', 'progress': 1.0},
    ];

    int currentStep = 0;
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (currentStep < uploadSteps.length) {
        setState(() {
          uploadProgress = uploadSteps[currentStep]['progress'] as double;
        });
        currentStep++;
      } else {
        timer.cancel();
        _uploadComplete();
      }
    });
  }

  void _uploadComplete() {
    setState(() {
      isUploading = false;
    });

    // Navigate to results screen with mock data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentResultsScreen(
          documentId: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          documentTitle: selectedFileName ?? 'Document',
          extractedText: _getMockExtractedText(),
          generatedQuestions: _getMockQuestions(),
          summary: _getMockSummary(),
        ),
      ),
    );
  }

  String _getMockExtractedText() {
    return '''
This is a sample document that has been processed using AI Document Master's OCR technology. The system successfully extracted text from the uploaded document and converted it into a digital format.

Key features of the extracted content:
- High accuracy text recognition
- Multi-language support
- Handwriting recognition capabilities
- Table and form extraction
- Document structure analysis

The AI-powered system can process various document types including PDFs, images, and scanned documents. It provides intelligent text extraction with context awareness and formatting preservation.

This mock text demonstrates the quality of OCR processing that users can expect from the AI Document Master system. The extracted content can be used for further processing, question generation, summarization, and analysis.
    ''';
  }

  List<Question> _getMockQuestions() {
    return [
      Question(
        id: 'q1',
        documentId: 'doc_1',
        questionText: 'What is the main purpose of AI Document Master?',
        type: QuestionType.mcq,
        difficulty: QuestionDifficulty.medium,
        options: [
          'Document storage',
          'AI-powered document processing',
          'File compression',
          'Image editing'
        ],
        correctAnswer: 'AI-powered document processing',
        createdAt: DateTime.now(),
      ),
      Question(
        id: 'q2',
        documentId: 'doc_1',
        questionText: 'What types of documents can AI Document Master process?',
        type: QuestionType.shortAnswer,
        difficulty: QuestionDifficulty.easy,
        options: [],
        correctAnswer: 'PDFs, images, and scanned documents',
        createdAt: DateTime.now(),
      ),
      Question(
        id: 'q3',
        documentId: 'doc_1',
        questionText: 'Explain the key features of the OCR technology used in AI Document Master.',
        type: QuestionType.longAnswer,
        difficulty: QuestionDifficulty.hard,
        options: [],
        correctAnswer: 'High accuracy text recognition, multi-language support, handwriting recognition, table and form extraction, document structure analysis',
        createdAt: DateTime.now(),
      ),
    ];
  }

  String _getMockSummary() {
    return '''
AI Document Master is an advanced document processing system that uses AI-powered OCR technology to extract text from various document types including PDFs, images, and scanned documents. The system offers high accuracy text recognition with multi-language support, handwriting recognition capabilities, and the ability to extract tables and forms while preserving document structure. The extracted content can be further processed for question generation, summarization, and analysis, making it a comprehensive solution for document digitization and management.
    ''';
  }

  void _showFeatureComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text('This feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Successful!'),
        content: const Text('Your document has been processed successfully. You can now view and edit it.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: const Text('View Document'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Supported file types:'),
              SizedBox(height: 8),
              Text('• Images: JPG, PNG, TIFF, BMP'),
              Text('• Documents: PDF, DOCX, TXT, RTF'),
              SizedBox(height: 16),
              Text('Compression profiles:'),
              SizedBox(height: 8),
              Text('• WhatsApp: 1MB (for sharing)'),
              Text('• Email: 5MB (for email attachments)'),
              Text('• College Portal: 10MB (for academic use)'),
              Text('• High Quality: 25MB (for printing)'),
              SizedBox(height: 16),
              Text('Processing features:'),
              SizedBox(height: 8),
              Text('• OCR: Always enabled for text extraction'),
              Text('• Handwriting Recognition: For handwritten content'),
              Text('• Question Generation: Creates questions from content'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
