import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/batch_processing_service.dart';
import '../services/image_processing_service.dart';
import '../providers/app_provider.dart';
import '../widgets/job_card.dart';

class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({Key? key}) : super(key: key);

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  // Job creation
  final TextEditingController _jobNameController = TextEditingController();
  List<File> _selectedFiles = [];
  List<ProcessingTask> _selectedTasks = [];
  BatchJobPriority _selectedPriority = BatchJobPriority.normal;
  
  // Batch processing service
  late BatchProcessingService _batchService;
  
  // Refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize batch service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      _batchService = BatchProcessingService(
        apiClient: appProvider.apiClient,
        imageService: appProvider.imageProcessingService,
        ocrService: appProvider.advancedOCRService,
      );
      
      // Set up global progress callback
      _batchService.setGlobalProgressCallback(_onGlobalProgress);
      
      // Start refresh timer
      _startRefreshTimer();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jobNameController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Batch Processing'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Create Job'),
            Tab(icon: Icon(Icons.queue), text: 'Queue'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateJobTab(),
          _buildQueueTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ==================== CREATE JOB TAB ====================
  
  Widget _buildCreateJobTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Name
          const Text(
            'Job Name',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _jobNameController,
            decoration: const InputDecoration(
              hintText: 'Enter job name (e.g., "Compress Vacation Photos")',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          
          // File Selection
          _buildFileSelectionSection(),
          const SizedBox(height: 24),
          
          // Task Selection
          _buildTaskSelectionSection(),
          const SizedBox(height: 24),
          
          // Priority Selection
          _buildPrioritySelectionSection(),
          const SizedBox(height: 32),
          
          // Create Job Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canCreateJob() ? _createJob : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Create & Start Job'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Files to Process',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_selectedFiles.length} files selected',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_selectedFiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No files selected',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Images'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhotos,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Processing Tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Task chips
        Wrap(
          spacing: 8,
          children: [
            _buildTaskChip('Compress', ProcessingType.compress),
            _buildTaskChip('Crop', ProcessingType.crop),
            _buildTaskChip('Enhance', ProcessingType.enhance),
            _buildTaskChip('OCR', ProcessingType.ocr),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Task details
        if (_selectedTasks.isNotEmpty) ...[
          const Text(
            'Task Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ..._selectedTasks.map((task) => _buildTaskDetailCard(task)),
        ],
      ],
    );
  }

  Widget _buildTaskChip(String label, ProcessingType type) {
    final isSelected = _selectedTasks.any((task) => task.type == type);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTasks.add(ProcessingTask(type: type));
          } else {
            _selectedTasks.removeWhere((task) => task.type == type);
          }
        });
      },
    );
  }

  Widget _buildTaskDetailCard(ProcessingTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTaskDisplayName(task.type),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedTasks.remove(task);
                    });
                  },
                ),
              ],
            ),
            if (task.type == ProcessingType.compress) ...[
              const SizedBox(height: 8),
              _buildCompressionControls(task),
            ] else if (task.type == ProcessingType.crop) ...[
              const SizedBox(height: 8),
              _buildCropControls(task),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionControls(ProcessingTask task) {
    int quality = task.parameters['quality'] ?? 85;
    int maxSize = task.parameters['maxFileSizeKB'] ?? 1000;
    
    return Column(
      children: [
        Row(
          children: [
            const Text('Quality: '),
            Expanded(
              child: Slider(
                value: quality.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                onChanged: (value) {
                  setState(() {
                    task.parameters['quality'] = value.round();
                  });
                },
              ),
            ),
            Text('${quality}%'),
          ],
        ),
        Row(
          children: [
            const Text('Max Size: '),
            Expanded(
              child: Slider(
                value: maxSize.toDouble(),
                min: 50,
                max: 5000,
                divisions: 99,
                onChanged: (value) {
                  setState(() {
                    task.parameters['maxFileSizeKB'] = value.round();
                  });
                },
              ),
            ),
            Text('${maxSize}KB'),
          ],
        ),
      ],
    );
  }

  Widget _buildCropControls(ProcessingTask task) {
    return Row(
      children: [
        const Text('Aspect Ratio: '),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: task.parameters['aspectRatio'] ?? 'free',
          items: const [
            DropdownMenuItem(value: 'free', child: Text('Free')),
            DropdownMenuItem(value: '1:1', child: Text('1:1 (Square)')),
            DropdownMenuItem(value: '4:3', child: Text('4:3')),
            DropdownMenuItem(value: '16:9', child: Text('16:9')),
            DropdownMenuItem(value: 'A4', child: Text('A4')),
          ],
          onChanged: (value) {
            setState(() {
              task.parameters['aspectRatio'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<BatchJobPriority>(
                title: const Text('Low'),
                subtitle: const Text('Process when resources available'),
                value: BatchJobPriority.low,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<BatchJobPriority>(
                title: const Text('Normal'),
                subtitle: const Text('Standard priority'),
                value: BatchJobPriority.normal,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<BatchJobPriority>(
                title: const Text('High'),
                subtitle: const Text('Process immediately'),
                value: BatchJobPriority.high,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== QUEUE TAB ====================
  
  Widget _buildQueueTab() {
    return Column(
      children: [
        // Statistics
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Queued',
                  _batchService.queueLength.toString(),
                  Icons.queue,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  _batchService.activeJobsCount.toString(),
                  Icons.play_arrow,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  _batchService.getCompletedJobs().length.toString(),
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),
        
        // Active Jobs
        Expanded(
          child: _batchService.getActiveJobs().isEmpty
              ? _buildEmptyState('No active jobs', Icons.play_arrow)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _batchService.getActiveJobs().length,
                  itemBuilder: (context, index) {
                    final job = _batchService.getActiveJobs()[index];
                    return JobCard(
                      job: job,
                      onCancel: () => _cancelJob(job.id),
                      onViewDetails: () => _viewJobDetails(job),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================== HISTORY TAB ====================
  
  Widget _buildHistoryTab() {
    final completedJobs = _batchService.getCompletedJobs();
    final failedJobs = _batchService.getFailedJobs();
    
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Completed'),
              Tab(text: 'Failed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Completed Jobs
                completedJobs.isEmpty
                    ? _buildEmptyState('No completed jobs', Icons.check_circle)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: completedJobs.length,
                        itemBuilder: (context, index) {
                          final job = completedJobs[index];
                          return JobCard(
                            job: job,
                            onViewDetails: () => _viewJobDetails(job),
                            onExport: () => _exportJobResults(job.id),
                          );
                        },
                      ),
                
                // Failed Jobs
                failedJobs.isEmpty
                    ? _buildEmptyState('No failed jobs', Icons.error)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: failedJobs.length,
                        itemBuilder: (context, index) {
                          final job = failedJobs[index];
                          return JobCard(
                            job: job,
                            onViewDetails: () => _viewJobDetails(job),
                            onRetry: () => _retryJob(job),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      return const SizedBox.shrink();
    }
    
    return FloatingActionButton(
      onPressed: _clearHistory,
      child: const Icon(Icons.clear_all),
      tooltip: 'Clear History',
    );
  }

  // ==================== ACTIONS ====================
  
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _takePhotos() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedFiles.add(File(photo.path));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  bool _canCreateJob() {
    return _jobNameController.text.isNotEmpty &&
           _selectedFiles.isNotEmpty &&
           _selectedTasks.isNotEmpty;
  }

  void _createJob() {
    if (!_canCreateJob()) return;
    
    final job = _batchService.createJob(
      name: _jobNameController.text,
      files: _selectedFiles,
      tasks: _selectedTasks,
      priority: _selectedPriority,
      metadata: {
        'created_by': 'user', // This would come from auth service
        'device': 'mobile',
      },
    );
    
    // Reset form
    _jobNameController.clear();
    _selectedFiles.clear();
    _selectedTasks.clear();
    _selectedPriority = BatchJobPriority.normal;
    
    // Switch to queue tab
    _tabController.animateTo(1);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job "${job.name}" created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelJob(String jobId) {
    final cancelled = _batchService.cancelJob(jobId);
    if (cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job cancelled successfully!')),
      );
    }
  }

  void _viewJobDetails(BatchJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${job.status.name}'),
              Text('Progress: ${(job.progress * 100).toStringAsFixed(1)}%'),
              Text('Files: ${job.files.length}'),
              Text('Tasks: ${job.tasks.length}'),
              if (job.error != null) ...[
                const SizedBox(height: 8),
                Text('Error: ${job.error}'),
              ],
              if (job.results.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...job.results.map((result) => Text(
                  '${result.originalFile.path}: ${result.success ? "Success" : "Failed"}',
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJobResults(String jobId) async {
    try {
      final file = await _batchService.exportJobResults(jobId, ExportFormat.csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results exported to: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _retryJob(BatchJob job) {
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retry functionality coming soon!')),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all completed and failed jobs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _batchService.clearCompletedJobs();
              _batchService.clearFailedJobs();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared!')),
              );
            },
            child: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Processing Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Max Concurrent Jobs: '),
                Expanded(
                  child: Slider(
                    value: _batchService.maxConcurrentJobs.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      _batchService.setMaxConcurrentJobs(value.round());
                    },
                  ),
                ),
                Text('${_batchService.maxConcurrentJobs}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITIES ====================
  
  String _getTaskDisplayName(ProcessingType type) {
    switch (type) {
      case ProcessingType.compress:
        return 'Image Compression';
      case ProcessingType.crop:
        return 'Image Cropping';
      case ProcessingType.enhance:
        return 'Image Enhancement';
      case ProcessingType.ocr:
        return 'Text Extraction (OCR)';
    }
  }

  void _onGlobalProgress(String jobId, double progress) {
    // This will be called when any job progress updates
    // We can use this to update the UI in real-time
    setState(() {
      // Trigger rebuild to show updated progress
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to refresh job statuses
        });
      }
    });
  }
}
