import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/question_model.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import '../widgets/document_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Document> recentDocuments = [];
  List<QuestionSet> recentQuestionSets = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for demonstration
    setState(() {
      recentDocuments = _getMockDocuments();
      recentQuestionSets = _getMockQuestionSets();
      isLoading = false;
    });
  }

  List<Document> _getMockDocuments() {
    return [
      Document(
        id: '1',
        userId: 'user1',
        fileName: 'Physics_Notes.pdf',
        originalFileUrl: 'https://example.com/physics_notes.pdf',
        type: DocumentType.pdf,
        status: DocumentStatus.completed,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        pages: [
          DocumentPage(
            id: 'page1',
            documentId: '1',
            pageNumber: 1,
            imageUrl: 'https://example.com/page1.jpg',
            ocrText: 'Sample OCR text for physics notes...',
            ocrConfidence: {'word1': 0.95, 'word2': 0.87},
            createdAt: DateTime.now(),
          ),
        ],
      ),
      Document(
        id: '2',
        userId: 'user1',
        fileName: 'Handwritten_Assignment.jpg',
        originalFileUrl: 'https://example.com/assignment.jpg',
        type: DocumentType.handwritten,
        status: DocumentStatus.processing,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        processingProgress: 0.65,
      ),
      Document(
        id: '3',
        userId: 'user1',
        fileName: 'Math_Test_Paper.pdf',
        originalFileUrl: 'https://example.com/math_test.pdf',
        type: DocumentType.pdf,
        status: DocumentStatus.completed,
        language: 'English',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        pages: [
          DocumentPage(
            id: 'page1',
            documentId: '3',
            pageNumber: 1,
            imageUrl: 'https://example.com/math_page1.jpg',
            ocrText: 'Mathematics test paper with equations...',
            ocrConfidence: {'equation1': 0.92, 'equation2': 0.88},
            createdAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }

  List<QuestionSet> _getMockQuestionSets() {
    return [
      QuestionSet(
        id: 'qs1',
        documentId: '1',
        title: 'Physics Chapter 1 Questions',
        description: 'Questions based on Mechanics and Motion',
        questions: [
          Question(
            id: 'q1',
            documentId: '1',
            questionText: 'What is Newton\'s First Law of Motion?',
            type: QuestionType.shortAnswer,
            difficulty: QuestionDifficulty.easy,
            createdAt: DateTime.now(),
          ),
          Question(
            id: 'q2',
            documentId: '1',
            questionText: 'Calculate the velocity of an object moving at 10 m/s for 5 seconds.',
            type: QuestionType.longAnswer,
            difficulty: QuestionDifficulty.medium,
            createdAt: DateTime.now(),
          ),
        ],
        overallDifficulty: QuestionDifficulty.medium,
        totalQuestions: 2,
        totalMarks: 20,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Show profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActionsSection(),
              const SizedBox(height: 24),
              
              // Statistics
              _buildStatisticsSection(),
              const SizedBox(height: 24),
              
              // Recent Documents
              _buildRecentDocumentsSection(),
              const SizedBox(height: 24),
              
              // Recent Question Sets
              _buildRecentQuestionSetsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.upload);
        },
        icon: const Icon(Icons.add),
        label: const Text('Upload Document'),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to process your documents with AI?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            QuickActionCard(
              title: 'Upload Document',
              subtitle: 'OCR & Processing',
              icon: Icons.upload_file,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.upload);
              },
            ),
            QuickActionCard(
              title: 'Generate Questions',
              subtitle: 'AI Question Creation',
              icon: Icons.quiz,
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.questionGenerator);
              },
            ),
            QuickActionCard(
              title: 'Batch Processing',
              subtitle: 'Multiple Documents',
              icon: Icons.batch_prediction,
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.batchManagement);
              },
            ),
            QuickActionCard(
              title: 'Admin Console',
              subtitle: 'Settings & Analytics',
              icon: Icons.admin_panel_settings,
              color: AppTheme.infoColor,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.adminConsole);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Total Documents',
                value: recentDocuments.length.toString(),
                icon: Icons.description,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatsCard(
                title: 'Question Sets',
                value: recentQuestionSets.length.toString(),
                icon: Icons.quiz,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Processing',
                value: recentDocuments
                    .where((doc) => doc.isProcessing)
                    .length
                    .toString(),
                icon: Icons.sync,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatsCard(
                title: 'Completed',
                value: recentDocuments
                    .where((doc) => doc.isCompleted)
                    .length
                    .toString(),
                icon: Icons.check_circle,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.recentDocuments,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all documents
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (recentDocuments.isEmpty)
          _buildEmptyState(
            'No documents yet',
            'Upload your first document to get started',
            Icons.description_outlined,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentDocuments.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DocumentCard(
                  document: recentDocuments[index],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.documentViewer,
                      arguments: recentDocuments[index],
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentQuestionSetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Question Sets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all question sets
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentQuestionSets.isEmpty)
          _buildEmptyState(
            'No question sets yet',
            'Generate questions from your documents',
            Icons.quiz_outlined,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentQuestionSets.length,
            itemBuilder: (context, index) {
              final questionSet = recentQuestionSets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.quiz,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  title: Text(
                    questionSet.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(questionSet.description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              '${questionSet.totalQuestions} Questions',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppTheme.secondaryColor),
                          ),
                          const SizedBox(width: 8),
                                                     Chip(
                             label: Text(
                               questionSet.overallDifficultyDisplayText,
                               style: const TextStyle(fontSize: 12),
                             ),
                             backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                             labelStyle: TextStyle(color: AppTheme.accentColor),
                           ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textSecondaryColor,
                  ),
                  onTap: () {
                    // TODO: Navigate to question set details
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.textHintColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
