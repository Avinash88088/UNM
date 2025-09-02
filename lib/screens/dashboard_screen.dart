import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${appProvider.error}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => appProvider.clearError(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${appProvider.currentUser?.displayName ?? 'User'}!',
                  style: AppTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${appProvider.currentUser?.email ?? 'No email'}',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Text(
                  'Features Coming Soon:',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  'Document Upload',
                  'Upload and process documents with AI',
                  Icons.upload_file,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  'OCR Processing',
                  'Extract text from images and documents',
                  Icons.text_fields,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  'Question Generation',
                  'Generate questions from documents',
                  Icons.quiz,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  'Batch Processing',
                  'Process multiple documents at once',
                  Icons.batch_prediction,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    await appProvider.logout();
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
