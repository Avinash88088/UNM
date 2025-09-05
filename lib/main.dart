import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen_premium.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'utils/dark_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
  
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
              child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'AI Document Master',
              debugShowCheckedModeBanner: false,
              theme: DarkTheme.theme,
              darkTheme: DarkTheme.theme,
              themeMode: ThemeMode.dark,
              home: const SplashScreen(),
              routes: {
                '/home': (context) => const HomeScreen(),
              },
            );
          },
        ),
    );
  }
}
