import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';
import 'image_processing_service.dart';
import 'advanced_ocr_service.dart';

class BatchProcessingService {
  final ApiClient _apiClient;
  final ImageProcessingService _imageService;
  final AdvancedOCRService _ocrService;
  final Uuid _uuid = Uuid();

  // Queue management
  final List<BatchJob> _jobQueue = [];
  final Map<String, BatchJob> _activeJobs = {};
  final Map<String, BatchJob> _completedJobs = {};
  final Map<String, BatchJob> _failedJobs = {};

  // Processing settings
  int _maxConcurrentJobs = 3;
  bool _isProcessing = false;
  Function(String, double)? _globalProgressCallback;

  BatchProcessingService({
    required ApiClient apiClient,
    required ImageProcessingService imageService,
    required AdvancedOCRService ocrService,
  })  : _apiClient = apiClient,
        _imageService = imageService,
        _ocrService = ocrService;

  // ==================== JOB MANAGEMENT ====================
  
  /// Create a new batch processing job
  BatchJob createJob({
    required String name,
    required List<File> files,
    required List<ProcessingTask> tasks,
    BatchJobPriority priority = BatchJobPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    final job = BatchJob(
      id: _uuid.v4(),
      name: name,
      files: files,
      tasks: tasks,
      priority: priority,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
    );

    _addJobToQueue(job);
    return job;
  }

  /// Add job to priority queue
  void _addJobToQueue(BatchJob job) {
    _jobQueue.add(job);
    _sortQueueByPriority();
    _processQueue();
  }

  /// Sort queue by priority
  void _sortQueueByPriority() {
    _jobQueue.sort((a, b) {
      final priorityOrder = {
        BatchJobPriority.high: 3,
        BatchJobPriority.normal: 2,
        BatchJobPriority.low: 1,
      };
      return priorityOrder[b.priority]!.compareTo(priorityOrder[a.priority]!);
    });
  }

  /// Process queue
  void _processQueue() {
    if (_isProcessing) return;
    
    while (_activeJobs.length < _maxConcurrentJobs && _jobQueue.isNotEmpty) {
      final job = _jobQueue.removeAt(0);
      _startJob(job);
    }
  }

  /// Start processing a job
  void _startJob(BatchJob job) {
    if (_activeJobs.containsKey(job.id)) return;

    job.status = BatchJobStatus.processing;
    job.startedAt = DateTime.now();
    _activeJobs[job.id] = job;

    _processJob(job);
  }

  /// Process a single job
  Future<void> _processJob(BatchJob job) async {
    try {
      final results = await _processFiles(job);
      
      job.results = results;
      job.status = BatchJobStatus.completed;
      job.completedAt = DateTime.now();
      
      _moveJobToCompleted(job);
      
    } catch (e) {
      job.status = BatchJobStatus.failed;
      job.error = e.toString();
      job.failedAt = DateTime.now();
      
      _moveJobToFailed(job);
    }

    _activeJobs.remove(job.id);
    _processQueue();
  }

  /// Move completed job to completed list
  void _moveJobToCompleted(BatchJob job) {
    _completedJobs[job.id] = job;
    _notifyJobUpdate(job);
  }

  /// Move failed job to failed list
  void _moveJobToFailed(BatchJob job) {
    _failedJobs[job.id] = job;
    _notifyJobUpdate(job);
  }

  /// Process multiple files with tasks
  Future<List<BatchFileResult>> _processFiles(BatchJob job) async {
    final results = <BatchFileResult>[];
    
    for (int i = 0; i < job.files.length; i++) {
      final file = job.files[i];
      final result = BatchFileResult(
        originalFile: file,
        processedFile: file,
        tasks: job.tasks,
        success: false,
        error: null,
        processingTime: Duration.zero,
      );

      try {
        final startTime = DateTime.now();
        
        // Process file with all tasks
        File currentFile = file;
        for (final task in job.tasks) {
          currentFile = await _processSingleTask(currentFile, task);
        }
        
        result.processedFile = currentFile;
        result.success = true;
        result.processingTime = DateTime.now().difference(startTime);
        
      } catch (e) {
        result.error = e.toString();
        result.success = false;
      }

      results.add(result);
      
      // Update progress
      final progress = (i + 1) / job.files.length;
      job.progress = progress;
      _notifyJobUpdate(job);
      
      // Global progress callback
      _globalProgressCallback?.call(job.id, progress);
    }
    
    return results;
  }

  /// Process a single task on a file
  Future<File> _processSingleTask(File file, ProcessingTask task) async {
    switch (task.type) {
      case ProcessingType.compress:
        return await _imageService.compressImage(
          imageFile: file,
          quality: task.parameters['quality'] ?? 85,
          maxFileSizeKB: task.parameters['maxFileSizeKB'],
        );
        
      case ProcessingType.crop:
        if (task.parameters['cropArea'] != null) {
          return await _imageService.cropImage(
            imageFile: file,
            cropArea: task.parameters['cropArea']!,
            shape: task.parameters['shape'] ?? CropShape.rectangle,
          );
        }
        return file;
        
      case ProcessingType.enhance:
        return await _imageService.autoEnhance(file);
        
      case ProcessingType.ocr:
        // OCR doesn't modify the file, but we can enhance it for better results
        if (task.parameters['enhance'] == true) {
          return await _imageService.autoEnhance(file);
        }
        return file;
        
      default:
        return file;
    }
  }

  // ==================== OCR BATCH PROCESSING ====================
  
  /// Process multiple images with OCR
  BatchOCRJob createOCRJob({
    required String name,
    required List<File> images,
    required OCRBatchOptions options,
    BatchJobPriority priority = BatchJobPriority.normal,
  }) {
    final job = BatchOCRJob(
      id: _uuid.v4(),
      name: name,
      images: images,
      options: options,
      priority: priority,
      createdAt: DateTime.now(),
    );

    _addJobToQueue(job);
    return job;
  }

  /// Process OCR batch job
  Future<void> _processOCRJob(BatchOCRJob job) async {
    try {
      final results = await _ocrService.processBatch(
        images: job.images,
        options: job.options,
        onProgress: (current, total) {
          job.progress = current / total;
          _notifyJobUpdate(job);
        },
      );
      
      job.ocrResults = results;
      job.status = BatchJobStatus.completed;
      job.completedAt = DateTime.now();
      
      _moveJobToCompleted(job);
      
    } catch (e) {
      job.status = BatchJobStatus.failed;
      job.error = e.toString();
      job.failedAt = DateTime.now();
      
      _moveJobToFailed(job);
    }
  }

  // ==================== QUEUE MANAGEMENT ====================
  
  /// Get all jobs in queue
  List<BatchJob> getQueuedJobs() => List.from(_jobQueue);
  
  /// Get active jobs
  List<BatchJob> getActiveJobs() => _activeJobs.values.toList();
  
  /// Get completed jobs
  List<BatchJob> getCompletedJobs() => _completedJobs.values.toList();
  
  /// Get failed jobs
  List<BatchJob> getFailedJobs() => _failedJobs.values.toList();
  
  /// Get job by ID
  BatchJob? getJob(String jobId) {
    return _activeJobs[jobId] ?? 
           _completedJobs[jobId] ?? 
           _failedJobs[jobId] ??
           _jobQueue.firstWhere((job) => job.id == jobId, orElse: () => throw Exception('Job not found'));
  }
  
  /// Cancel a job
  bool cancelJob(String jobId) {
    // Remove from queue
    final queuedIndex = _jobQueue.indexWhere((job) => job.id == jobId);
    if (queuedIndex != -1) {
      final job = _jobQueue.removeAt(queuedIndex);
      job.status = BatchJobStatus.cancelled;
      job.cancelledAt = DateTime.now();
      _completedJobs[job.id] = job;
      return true;
    }
    
    // Cancel active job
    if (_activeJobs.containsKey(jobId)) {
      final job = _activeJobs[jobId]!;
      job.status = BatchJobStatus.cancelled;
      job.cancelledAt = DateTime.now();
      _activeJobs.remove(jobId);
      _completedJobs[job.id] = job;
      return true;
    }
    
    return false;
  }
  
  /// Clear completed jobs
  void clearCompletedJobs() {
    _completedJobs.clear();
  }
  
  /// Clear failed jobs
  void clearFailedJobs() {
    _failedJobs.clear();
  }
  
  /// Clear all jobs
  void clearAllJobs() {
    _jobQueue.clear();
    _activeJobs.clear();
    _completedJobs.clear();
    _failedJobs.clear();
  }

  // ==================== SETTINGS & CONFIGURATION ====================
  
  /// Set maximum concurrent jobs
  void setMaxConcurrentJobs(int max) {
    _maxConcurrentJobs = max;
    _processQueue();
  }
  
  /// Get maximum concurrent jobs
  int get maxConcurrentJobs => _maxConcurrentJobs;
  
  /// Set global progress callback
  void setGlobalProgressCallback(Function(String, double)? callback) {
    _globalProgressCallback = callback;
  }
  
  /// Get processing status
  bool get isProcessing => _isProcessing;
  
  /// Get queue length
  int get queueLength => _jobQueue.length;
  
  /// Get active jobs count
  int get activeJobsCount => _activeJobs.length;

  // ==================== EXPORT & UTILITIES ====================
  
  /// Export job results
  Future<File> exportJobResults(String jobId, ExportFormat format) async {
    final job = getJob(jobId);
    if (job == null) throw Exception('Job not found');
    
    final tempDir = await getTemporaryDirectory();
    final fileName = 'batch_results_${job.id}_${DateTime.now().millisecondsSinceEpoch}.$format.extension';
    final file = File('${tempDir.path}/$fileName');
    
    String content = '';
    switch (format) {
      case ExportFormat.json:
        content = json.encode(job.toJson());
        break;
      case ExportFormat.csv:
        content = _convertJobToCSV(job);
        break;
      case ExportFormat.txt:
        content = _convertJobToText(job);
        break;
    }
    
    await file.writeAsString(content);
    return file;
  }
  
  /// Convert job to CSV
  String _convertJobToCSV(BatchJob job) {
    final buffer = StringBuffer();
    buffer.writeln('File,Status,Processing Time,Error');
    
    for (final result in job.results) {
      buffer.writeln('${result.originalFile.path},${result.success ? "Success" : "Failed"},${result.processingTime.inMilliseconds}ms,${result.error ?? ""}');
    }
    
    return buffer.toString();
  }
  
  /// Convert job to text
  String _convertJobToText(BatchJob job) {
    final buffer = StringBuffer();
    buffer.writeln('Batch Job: ${job.name}');
    buffer.writeln('Status: ${job.status.name}');
    buffer.writeln('Files: ${job.files.length}');
    buffer.writeln('Tasks: ${job.tasks.length}');
    buffer.writeln('Progress: ${(job.progress * 100).toStringAsFixed(1)}%');
    buffer.writeln('');
    
    for (int i = 0; i < job.results.length; i++) {
      final result = job.results[i];
      buffer.writeln('File ${i + 1}: ${result.originalFile.path}');
      buffer.writeln('  Status: ${result.success ? "Success" : "Failed"}');
      buffer.writeln('  Processing Time: ${result.processingTime.inMilliseconds}ms');
      if (result.error != null) {
        buffer.writeln('  Error: ${result.error}');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  // ==================== NOTIFICATIONS ====================
  
  /// Notify job update
  void _notifyJobUpdate(BatchJob job) {
    // This can be extended to notify listeners about job updates
    // For now, we'll just print to console
    print('Job ${job.id} updated: ${job.status.name} - ${(job.progress * 100).toStringAsFixed(1)}%');
  }
  
  /// Get job statistics
  Map<String, dynamic> getJobStatistics() {
    return {
      'queued': _jobQueue.length,
      'active': _activeJobs.length,
      'completed': _completedJobs.length,
      'failed': _failedJobs.length,
      'total': _jobQueue.length + _activeJobs.length + _completedJobs.length + _failedJobs.length,
    };
  }
}

// ==================== ENUMS ====================

enum BatchJobStatus { queued, processing, completed, failed, cancelled }

enum BatchJobPriority { low, normal, high }

enum ExportFormat { json, csv, txt }

// ==================== MODELS ====================

class BatchJob {
  final String id;
  final String name;
  final List<File> files;
  final List<ProcessingTask> tasks;
  final BatchJobPriority priority;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  
  DateTime? startedAt;
  DateTime? completedAt;
  DateTime? failedAt;
  DateTime? cancelledAt;
  
  BatchJobStatus status = BatchJobStatus.queued;
  double progress = 0.0;
  String? error;
  List<BatchFileResult> results = [];

  BatchJob({
    required this.id,
    required this.name,
    required this.files,
    required this.tasks,
    required this.priority,
    required this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'files': files.map((f) => f.path).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'priority': priority.name,
      'metadata': metadata,
      'status': status.name,
      'progress': progress,
      'error': error,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failed_at': failedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    };
  }
}

class BatchOCRJob extends BatchJob {
  final List<File> images;
  final OCRBatchOptions options;
  List<OCRResult>? ocrResults;

  BatchOCRJob({
    required super.id,
    required super.name,
    required this.images,
    required this.options,
    required super.priority,
    super.metadata = const {},
    required super.createdAt,
  }) : super(
    files: images,
    tasks: [],
  );

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson['ocr_results'] = ocrResults?.map((r) => r.toJson()).toList();
    baseJson['options'] = {
      'language': options.language,
      'enhance_image': options.enhanceImage,
      'mode': options.mode.name,
      'max_concurrent': options.maxConcurrent,
    };
    return baseJson;
  }
}

class BatchFileResult {
  final File originalFile;
  File processedFile;
  final List<ProcessingTask> tasks;
  bool success;
  String? error;
  Duration processingTime;

  BatchFileResult({
    required this.originalFile,
    required this.processedFile,
    required this.tasks,
    required this.success,
    this.error,
    required this.processingTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'original_file': originalFile.path,
      'processed_file': processedFile.path,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'success': success,
      'error': error,
      'processing_time_ms': processingTime.inMilliseconds,
    };
  }
}

// ==================== EXTENSIONS ====================

extension ExportFormatExtension on ExportFormat {
  String get extension {
    switch (this) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.txt:
        return 'txt';
    }
  }
}

extension ProcessingTaskExtension on ProcessingTask {
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'parameters': parameters,
    };
  }
}
