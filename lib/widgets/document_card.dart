import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../utils/app_theme.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final bool showActions;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildDocumentIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.fileName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(),
                            const SizedBox(width: 8),
                            _buildTypeChip(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showActions) _buildActionMenu(context),
                ],
              ),
              const SizedBox(height: 16),
              _buildDocumentDetails(context),
              if (document.isProcessing) _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (document.type) {
      case DocumentType.pdf:
        iconData = Icons.picture_as_pdf;
        iconColor = AppTheme.errorColor;
        break;
      case DocumentType.image:
        iconData = Icons.image;
        iconColor = AppTheme.primaryColor;
        break;
      case DocumentType.word:
        iconData = Icons.description;
        iconColor = AppTheme.infoColor;
        break;
      case DocumentType.handwritten:
        iconData = Icons.edit;
        iconColor = AppTheme.accentColor;
        break;
      case DocumentType.text:
        iconData = Icons.text_fields;
        iconColor = AppTheme.secondaryColor;
        break;
      case DocumentType.mixed:
        iconData = Icons.folder;
        iconColor = AppTheme.warningColor;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    IconData statusIcon;
    
    switch (document.status) {
      case DocumentStatus.uploaded:
        chipColor = AppTheme.infoColor;
        statusIcon = Icons.upload;
        break;
      case DocumentStatus.processing:
        chipColor = AppTheme.warningColor;
        statusIcon = Icons.sync;
        break;
      case DocumentStatus.ocrCompleted:
        chipColor = AppTheme.primaryColor;
        statusIcon = Icons.text_fields;
        break;
      case DocumentStatus.handwritingRecognitionCompleted:
        chipColor = AppTheme.secondaryColor;
        statusIcon = Icons.edit;
        break;
      case DocumentStatus.completed:
        chipColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case DocumentStatus.failed:
        chipColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            document.statusDisplayText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.textHintColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textHintColor.withOpacity(0.3)),
      ),
      child: Text(
        document.typeDisplayText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppTheme.textSecondaryColor,
      ),
      onSelected: (value) {
        _handleActionSelection(context, value);
      },
      itemBuilder: (context) => [
        if (document.canEdit)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        if (document.canEdit)
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 8),
                Text('Export'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 18),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentDetails(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.language,
                'Language: ${document.language ?? 'Auto-detect'}',
              ),
              const SizedBox(height: 4),
              _buildDetailRow(
                Icons.schedule,
                'Uploaded: ${_formatDate(document.createdAt)}',
              ),
              if (document.pages != null && document.pages!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildDetailRow(
                    Icons.pages,
                    'Pages: ${document.pages!.length}',
                  ),
                ),
            ],
          ),
        ),
        if (document.pages != null && document.pages!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Confidence',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              _buildConfidenceIndicator(),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator() {
    if (document.pages == null || document.pages!.isEmpty) {
      return const SizedBox.shrink();
    }

    double averageConfidence = document.pages!
        .map((page) => page.averageOcrConfidence)
        .reduce((a, b) => a + b) / document.pages!.length;

    Color confidenceColor;
    if (averageConfidence >= 0.8) {
      confidenceColor = AppTheme.successColor;
    } else if (averageConfidence >= 0.6) {
      confidenceColor = AppTheme.warningColor;
    } else {
      confidenceColor = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: confidenceColor.withOpacity(0.3)),
      ),
      child: Text(
        '${(averageConfidence * 100).toInt()}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: confidenceColor,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Processing...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (document.processingProgress != null)
              Text(
                '${(document.processingProgress! * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: document.processingProgress ?? 0.0,
          backgroundColor: AppTheme.dividerColor,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleActionSelection(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to document editor
        break;
      case 'export':
        // TODO: Show export options
        break;
      case 'share':
        // TODO: Show share options
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.fileName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Delete document
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
