import 'package:flutter/material.dart';
import '../services/batch_processing_service.dart';

class JobCard extends StatelessWidget {
  final BatchJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onViewDetails;
  final VoidCallback? onExport;
  final VoidCallback? onRetry;

  const JobCard({
    Key? key,
    required this.job,
    this.onCancel,
    this.onViewDetails,
    this.onExport,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${job.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Section
            if (job.status == BatchJobStatus.processing) ...[
              _buildProgressSection(context),
              const SizedBox(height: 16),
            ],
            
            // Job Info
            _buildJobInfo(),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    IconData icon;
    
    switch (job.status) {
      case BatchJobStatus.queued:
        color = Colors.blue;
        icon = Icons.queue;
        break;
      case BatchJobStatus.processing:
        color = Colors.orange;
        icon = Icons.play_arrow;
        break;
      case BatchJobStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BatchJobStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case BatchJobStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            job.status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(job.progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: job.progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildJobInfo() {
    return Column(
      children: [
        _buildInfoRow('Files', '${job.files.length}'),
        _buildInfoRow('Tasks', '${job.tasks.length}'),
        _buildInfoRow('Priority', _getPriorityText(job.priority)),
        _buildInfoRow('Created', _formatDateTime(job.createdAt)),
        
        if (job.startedAt != null)
          _buildInfoRow('Started', _formatDateTime(job.startedAt!)),
        
        if (job.completedAt != null)
          _buildInfoRow('Completed', _formatDateTime(job.completedAt!)),
        
        if (job.failedAt != null)
          _buildInfoRow('Failed', _formatDateTime(job.failedAt!)),
        
        if (job.cancelledAt != null)
          _buildInfoRow('Cancelled', _formatDateTime(job.cancelledAt!)),
        
        if (job.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onViewDetails != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details'),
            ),
          ),
        
        if (onViewDetails != null && onCancel != null)
          const SizedBox(width: 8),
        
        if (onCancel != null && job.status == BatchJobStatus.processing)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        
        if (onExport != null && job.status == BatchJobStatus.completed)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ),
        
        if (onRetry != null && job.status == BatchJobStatus.failed)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  String _getPriorityText(BatchJobPriority priority) {
    switch (priority) {
      case BatchJobPriority.low:
        return 'Low';
      case BatchJobPriority.normal:
        return 'Normal';
      case BatchJobPriority.high:
        return 'High';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ==================== SPECIALIZED JOB CARDS ====================

class OCRJobCard extends StatelessWidget {
  final BatchOCRJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onViewDetails;
  final VoidCallback? onExport;

  const OCRJobCard({
    Key? key,
    required this.job,
    this.onCancel,
    this.onViewDetails,
    this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'OCR Batch Job',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Section
            if (job.status == BatchJobStatus.processing) ...[
              _buildProgressSection(context),
              const SizedBox(height: 16),
            ],
            
            // OCR Specific Info
            _buildOCRInfo(),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                if (onViewDetails != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Details'),
                    ),
                  ),
                
                if (onViewDetails != null && onCancel != null)
                  const SizedBox(width: 8),
                
                if (onCancel != null && job.status == BatchJobStatus.processing)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                
                if (onExport != null && job.status == BatchJobStatus.completed)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onExport,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    IconData icon;
    
    switch (job.status) {
      case BatchJobStatus.queued:
        color = Colors.blue;
        icon = Icons.queue;
        break;
      case BatchJobStatus.processing:
        color = Colors.orange;
        icon = Icons.play_arrow;
        break;
      case BatchJobStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BatchJobStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case BatchJobStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            job.status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(job.progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: job.progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOCRInfo() {
    return Column(
      children: [
        _buildInfoRow('Images', '${job.images.length}'),
        _buildInfoRow('Language', job.options.language ?? 'Auto'),
        _buildInfoRow('Mode', job.options.mode.name),
        _buildInfoRow('Enhance', job.options.enhanceImage ? 'Yes' : 'No'),
        _buildInfoRow('Created', _formatDateTime(job.createdAt)),
        
        if (job.startedAt != null)
          _buildInfoRow('Started', _formatDateTime(job.startedAt!)),
        
        if (job.completedAt != null)
          _buildInfoRow('Completed', _formatDateTime(job.completedAt!)),
        
        if (job.ocrResults != null && job.ocrResults!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${job.ocrResults!.length} images processed successfully',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
