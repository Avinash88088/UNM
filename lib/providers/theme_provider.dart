import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';
  static const String _customPrimaryKey = 'custom_primary';
  static const String _customSecondaryKey = 'custom_secondary';
  static const String _customAccentKey = 'custom_accent';
  static const String _highContrastKey = 'high_contrast';
  static const String _largeTextKey = 'large_text';
  static const String _reduceMotionKey = 'reduce_motion';

  ThemeMode _themeMode = ThemeMode.system;
  String _colorScheme = 'default';
  Color _customPrimaryColor = const Color(0xFF2196F3);
  Color _customSecondaryColor = const Color(0xFF03DAC6);
  Color _customAccentColor = const Color(0xFFFF4081);
  bool _highContrast = false;
  bool _largeText = false;
  bool _reduceMotion = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get colorScheme => _colorScheme;
  Color get customPrimaryColor => _customPrimaryColor;
  Color get customSecondaryColor => _customSecondaryColor;
  Color get customAccentColor => _customAccentColor;
  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  bool get reduceMotion => _reduceMotion;

  // Color schemes
  static const Map<String, ColorScheme> _colorSchemes = {
    'default': ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF5F5F5),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
    ),
    'green': ColorScheme.light(
      primary: Color(0xFF4CAF50),
      secondary: Color(0xFF8BC34A),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF1F8E9),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
    ),
    'purple': ColorScheme.light(
      primary: Color(0xFF9C27B0),
      secondary: Color(0xFFE91E63),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFFCE4EC),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
    ),
    'orange': ColorScheme.light(
      primary: Color(0xFFFF9800),
      secondary: Color(0xFFFF5722),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFFFF3E0),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
    ),
    'red': ColorScheme.light(
      primary: Color(0xFFF44336),
      secondary: Color(0xFFE91E63),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFFFEBEE),
      error: Color(0xFFB00020),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
    ),
  };

  static const Map<String, ColorScheme> _darkColorSchemes = {
    'default': ColorScheme.dark(
      primary: Color(0xFF90CAF9),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
    ),
    'green': ColorScheme.dark(
      primary: Color(0xFF81C784),
      secondary: Color(0xFFAED581),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
    ),
    'purple': ColorScheme.dark(
      primary: Color(0xFFBA68C8),
      secondary: Color(0xFFF48FB1),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
    ),
    'orange': ColorScheme.dark(
      primary: Color(0xFFFFB74D),
      secondary: Color(0xFFFF8A65),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
    ),
    'red': ColorScheme.dark(
      primary: Color(0xFFEF5350),
      secondary: Color(0xFFF48FB1),
      surface: Color(0xFF121212),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFF000000),
    ),
  };

  // Initialize theme from shared preferences
  Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    // Load color scheme
    _colorScheme = prefs.getString(_colorSchemeKey) ?? 'default';
    
    // Load custom colors
    final primaryColorValue = prefs.getInt(_customPrimaryKey);
    if (primaryColorValue != null) {
      _customPrimaryColor = Color(primaryColorValue);
    }
    
    final secondaryColorValue = prefs.getInt(_customSecondaryKey);
    if (secondaryColorValue != null) {
      _customSecondaryColor = Color(secondaryColorValue);
    }
    
    final accentColorValue = prefs.getInt(_customAccentKey);
    if (accentColorValue != null) {
      _customAccentColor = Color(accentColorValue);
    }
    
    // Load accessibility settings
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _largeText = prefs.getBool(_largeTextKey) ?? false;
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    
    notifyListeners();
  }

  // Theme mode methods
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }

  void _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }

  // Color scheme methods
  void setColorScheme(String scheme) {
    _colorScheme = scheme;
    _saveColorScheme();
    notifyListeners();
  }

  void _saveColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, _colorScheme);
  }

  // Custom color methods
  void setCustomPrimaryColor(Color color) {
    _customPrimaryColor = color;
    _saveCustomPrimaryColor();
    notifyListeners();
  }

  void _saveCustomPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customPrimaryKey, _customPrimaryColor.value);
  }

  void setCustomSecondaryColor(Color color) {
    _customSecondaryColor = color;
    _saveCustomSecondaryColor();
    notifyListeners();
  }

  void _saveCustomSecondaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customSecondaryKey, _customSecondaryColor.value);
  }

  void setCustomAccentColor(Color color) {
    _customAccentColor = color;
    _saveCustomAccentColor();
    notifyListeners();
  }

  void _saveCustomAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customAccentKey, _customAccentColor.value);
  }

  // Accessibility methods
  void setHighContrast(bool value) {
    _highContrast = value;
    _saveHighContrast();
    notifyListeners();
  }

  void _saveHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, _highContrast);
  }

  void setLargeText(bool value) {
    _largeText = value;
    _saveLargeText();
    notifyListeners();
  }

  void _saveLargeText() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_largeTextKey, _largeText);
  }

  void setReduceMotion(bool value) {
    _reduceMotion = value;
    _saveReduceMotion();
    notifyListeners();
  }

  void _saveReduceMotion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, _reduceMotion);
  }

  // Get current theme data
  ThemeData getLightTheme() {
    ColorScheme baseColorScheme = _colorSchemes[_colorScheme] ?? _colorSchemes['default']!;
    
    if (_highContrast) {
      baseColorScheme = baseColorScheme.copyWith(
        primary: Colors.black,
        secondary: Colors.black,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      textTheme: _largeText ? _getLargeTextTheme() : null,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: _reduceMotion 
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null,
    );
  }

  ThemeData getDarkTheme() {
    ColorScheme baseColorScheme = _darkColorSchemes[_colorScheme] ?? _darkColorSchemes['default']!;
    
    if (_highContrast) {
      baseColorScheme = baseColorScheme.copyWith(
        primary: Colors.white,
        secondary: Colors.white,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      textTheme: _largeText ? _getLargeTextTheme() : null,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: _reduceMotion 
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null,
    );
  }

  TextTheme _getLargeTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 32),
      displayMedium: TextStyle(fontSize: 28),
      displaySmall: TextStyle(fontSize: 24),
      headlineLarge: TextStyle(fontSize: 22),
      headlineMedium: TextStyle(fontSize: 20),
      headlineSmall: TextStyle(fontSize: 18),
      titleLarge: TextStyle(fontSize: 16),
      titleMedium: TextStyle(fontSize: 14),
      titleSmall: TextStyle(fontSize: 12),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
      labelLarge: TextStyle(fontSize: 14),
      labelMedium: TextStyle(fontSize: 12),
      labelSmall: TextStyle(fontSize: 10),
    );
  }

  // Reset to default
  void resetToDefault() {
    _themeMode = ThemeMode.system;
    _colorScheme = 'default';
    _customPrimaryColor = const Color(0xFF2196F3);
    _customSecondaryColor = const Color(0xFF03DAC6);
    _customAccentColor = const Color(0xFFFF4081);
    _highContrast = false;
    _largeText = false;
    _reduceMotion = false;
    
    _saveAllSettings();
    notifyListeners();
  }

  // Save all settings
  void saveTheme() {
    _saveAllSettings();
  }

  void _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_themeModeKey, _themeMode.index),
      prefs.setString(_colorSchemeKey, _colorScheme),
      prefs.setInt(_customPrimaryKey, _customPrimaryColor.value),
      prefs.setInt(_customSecondaryKey, _customSecondaryColor.value),
      prefs.setInt(_customAccentKey, _customAccentColor.value),
      prefs.setBool(_highContrastKey, _highContrast),
      prefs.setBool(_largeTextKey, _largeText),
      prefs.setBool(_reduceMotionKey, _reduceMotion),
    ]);
  }

  // Export theme settings
  Map<String, dynamic> exportTheme() {
    return {
      'themeMode': _themeMode.index,
      'colorScheme': _colorScheme,
      'customPrimaryColor': _customPrimaryColor.value,
      'customSecondaryColor': _customSecondaryColor.value,
      'customAccentColor': _customAccentColor.value,
      'highContrast': _highContrast,
      'largeText': _largeText,
      'reduceMotion': _reduceMotion,
    };
  }

  // Import theme settings
  void importTheme(Map<String, dynamic> themeData) {
    _themeMode = ThemeMode.values[themeData['themeMode'] ?? 0];
    _colorScheme = themeData['colorScheme'] ?? 'default';
    _customPrimaryColor = Color(themeData['customPrimaryColor'] ?? 0xFF2196F3);
    _customSecondaryColor = Color(themeData['customSecondaryColor'] ?? 0xFF03DAC6);
    _customAccentColor = Color(themeData['customAccentColor'] ?? 0xFFFF4081);
    _highContrast = themeData['highContrast'] ?? false;
    _largeText = themeData['largeText'] ?? false;
    _reduceMotion = themeData['reduceMotion'] ?? false;
    
    _saveAllSettings();
    notifyListeners();
  }
}
