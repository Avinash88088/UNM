import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/question_generator_screen.dart';
import 'screens/batch_management_screen.dart';
import 'screens/admin_console_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AIDocumentMasterApp());
}

class AIDocumentMasterApp extends StatelessWidget {
  const AIDocumentMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Document Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.dashboard,
      routes: {
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.upload: (context) => const UploadScreen(),
        AppRoutes.documentViewer: (context) => const DocumentViewerScreen(),
        AppRoutes.questionGenerator: (context) => const QuestionGeneratorScreen(),
        AppRoutes.batchManagement: (context) => const BatchManagementScreen(),
        AppRoutes.adminConsole: (context) => const AdminConsoleScreen(),
      },
    );
  }
}
