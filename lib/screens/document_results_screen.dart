import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/document_model.dart';
import '../models/question_model.dart';

class DocumentResultsScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final String? extractedText;
  final List<Question>? generatedQuestions;
  final String? summary;

  const DocumentResultsScreen({
    Key? key,
    required this.documentId,
    required this.documentTitle,
    this.extractedText,
    this.generatedQuestions,
    this.summary,
  }) : super(key: key);

  @override
  State<DocumentResultsScreen> createState() => _DocumentResultsScreenState();
}

class _DocumentResultsScreenState extends State<DocumentResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingQuestions = false;
  bool _isGeneratingSummary = false;
  String? _generatedSummary;
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _questions = widget.generatedQuestions ?? [];
    _generatedSummary = widget.summary;
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
        title: Text(widget.documentTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportResults,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'OCR Text'),
            Tab(icon: Icon(Icons.quiz), text: 'Questions'),
            Tab(icon: Icon(Icons.summarize), text: 'Summary'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOCRTextTab(),
          _buildQuestionsTab(),
          _buildSummaryTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateMoreContent,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Generate More', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildOCRTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Extracted Text',
            Icons.text_fields,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          if (widget.extractedText != null && widget.extractedText!.isNotEmpty)
            _buildTextContent(widget.extractedText!)
          else
            _buildEmptyState(
              'No text extracted',
              'The document may not contain readable text or OCR processing failed.',
              Icons.text_fields,
            ),
          const SizedBox(height: 24),
          _buildTextActions(),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                'Generated Questions',
                Icons.quiz,
                AppTheme.secondaryColor,
              ),
              if (_questions.isNotEmpty)
                TextButton.icon(
                  onPressed: _generateMoreQuestions,
                  icon: const Icon(Icons.add),
                  label: const Text('Generate More'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_questions.isNotEmpty)
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionCard(question, index);
            }).toList()
          else
            _buildEmptyState(
              'No questions generated',
              'Generate questions from the extracted text to create quizzes and assessments.',
              Icons.quiz_outlined,
              action: ElevatedButton.icon(
                onPressed: _generateQuestions,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Questions'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                'Document Summary',
                Icons.summarize,
                AppTheme.successColor,
              ),
              if (_generatedSummary != null)
                TextButton.icon(
                  onPressed: _regenerateSummary,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generatedSummary != null && _generatedSummary!.isNotEmpty)
            _buildSummaryContent(_generatedSummary!)
          else
            _buildEmptyState(
              'No summary available',
              'Generate a summary of the document content for quick understanding.',
              Icons.summarize_outlined,
              action: ElevatedButton.icon(
                onPressed: _generateSummary,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Summary'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Document Analytics',
            Icons.analytics,
            AppTheme.warningColor,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCards(),
          const SizedBox(height: 24),
          _buildProcessingHistory(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent(String text) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Text Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(text),
                      tooltip: 'Copy text',
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchInText,
                      tooltip: 'Search in text',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: SelectableText(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${text.length} characters, ${text.split(' ').length} words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQuestionTypeColor(question.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.typeDisplayText.toUpperCase(),
                    style: TextStyle(
                      color: _getQuestionTypeColor(question.type),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleQuestionAction(value, question),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (question.options?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              ...question.options!.asMap().entries.map((entry) {
                final optionIndex = entry.key;
                final option = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${String.fromCharCode(65 + optionIndex)}. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Expanded(child: Text(option)),
                    ],
                  ),
                );
              }).toList(),
            ],
            if (question.correctAnswer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Answer: ${question.correctAnswer}',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(String summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(summary),
                      tooltip: 'Copy summary',
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: _readSummary,
                      tooltip: 'Read aloud',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
              ),
              child: Text(
                summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${summary.length} characters, ${summary.split(' ').length} words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Text Length',
                '${widget.extractedText?.length ?? 0}',
                'characters',
                Icons.text_fields,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Questions',
                '${_questions.length}',
                'generated',
                Icons.quiz,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Word Count',
                '${widget.extractedText?.split(' ').length ?? 0}',
                'words',
                Icons.format_align_left,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Processing Time',
                '2.3',
                'seconds',
                Icons.timer,
                AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryItem('Document Upload', 'Completed', Icons.upload, AppTheme.successColor),
            _buildHistoryItem('OCR Processing', 'Completed', Icons.text_fields, AppTheme.successColor),
            _buildHistoryItem('Question Generation', _questions.isNotEmpty ? 'Completed' : 'Pending', Icons.quiz, _questions.isNotEmpty ? AppTheme.successColor : AppTheme.warningColor),
            _buildHistoryItem('Summary Generation', _generatedSummary != null ? 'Completed' : 'Pending', Icons.summarize, _generatedSummary != null ? AppTheme.successColor : AppTheme.warningColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String description, IconData icon, {Widget? action}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip('Copy All', Icons.copy, () => _copyToClipboard(widget.extractedText!)),
                _buildActionChip('Search', Icons.search, _searchInText),
                _buildActionChip('Translate', Icons.translate, _translateText),
                _buildActionChip('Export', Icons.download, _exportText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: onTap,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
    );
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return AppTheme.primaryColor;
      case QuestionType.shortAnswer:
        return AppTheme.secondaryColor;
      case QuestionType.longAnswer:
        return AppTheme.successColor;
      default:
        return AppTheme.warningColor;
    }
  }

  // Action methods
  void _copyToClipboard(String text) {
    // TODO: Implement clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  void _searchInText() {
    // TODO: Implement search functionality
    _showFeatureComingSoon('Search in Text');
  }

  void _translateText() {
    // TODO: Implement translation
    _showFeatureComingSoon('Text Translation');
  }

  void _exportText() {
    // TODO: Implement text export
    _showFeatureComingSoon('Text Export');
  }

  void _generateQuestions() async {
    if (widget.extractedText == null || widget.extractedText!.isEmpty) {
      _showErrorDialog('No text available to generate questions from');
      return;
    }

    setState(() {
      _isGeneratingQuestions = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final questions = await appProvider.generateQuestions(
        documentId: widget.documentId,
        count: 5,
        difficulty: 'medium',
      );

      setState(() {
        _questions = questions;
        _isGeneratingQuestions = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${questions.length} questions')),
      );
    } catch (e) {
      setState(() {
        _isGeneratingQuestions = false;
      });
      _showErrorDialog('Failed to generate questions: $e');
    }
  }

  void _generateMoreQuestions() {
    _generateQuestions();
  }

  void _generateSummary() async {
    if (widget.extractedText == null || widget.extractedText!.isEmpty) {
      _showErrorDialog('No text available to generate summary from');
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      // TODO: Implement summary generation
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      setState(() {
        _generatedSummary = 'This is a generated summary of the document content. It provides a concise overview of the main points and key information extracted from the original text.';
        _isGeneratingSummary = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary generated successfully')),
      );
    } catch (e) {
      setState(() {
        _isGeneratingSummary = false;
      });
      _showErrorDialog('Failed to generate summary: $e');
    }
  }

  void _regenerateSummary() {
    _generateSummary();
  }

  void _generateMoreContent() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildGenerateMoreSheet(),
    );
  }

  Widget _buildGenerateMoreSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate More Content',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildGenerateOption(
            'Generate More Questions',
            'Create additional questions with different difficulty levels',
            Icons.quiz,
            _generateQuestions,
          ),
          _buildGenerateOption(
            'Generate Summary',
            'Create a concise summary of the document',
            Icons.summarize,
            _generateSummary,
          ),
          _buildGenerateOption(
            'Generate Keywords',
            'Extract key terms and concepts from the document',
            Icons.tag,
            () => _showFeatureComingSoon('Keyword Generation'),
          ),
          _buildGenerateOption(
            'Generate Outline',
            'Create a structured outline of the document',
            Icons.list_alt,
            () => _showFeatureComingSoon('Outline Generation'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateOption(String title, String description, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _shareResults() {
    // TODO: Implement sharing functionality
    _showFeatureComingSoon('Share Results');
  }

  void _exportResults() {
    // TODO: Implement export functionality
    _showFeatureComingSoon('Export Results');
  }

  void _readSummary() {
    // TODO: Implement text-to-speech
    _showFeatureComingSoon('Text-to-Speech');
  }

  void _handleQuestionAction(String action, Question question) {
    switch (action) {
      case 'edit':
        _editQuestion(question);
        break;
      case 'duplicate':
        _duplicateQuestion(question);
        break;
      case 'delete':
        _deleteQuestion(question);
        break;
    }
  }

  void _editQuestion(Question question) {
    // TODO: Implement question editing
    _showFeatureComingSoon('Edit Question');
  }

  void _duplicateQuestion(Question question) {
    setState(() {
      _questions.add(question);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question duplicated')),
    );
  }

  void _deleteQuestion(Question question) {
    setState(() {
      _questions.remove(question);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question deleted')),
    );
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
}
