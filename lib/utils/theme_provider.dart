// Theme provider for the app
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';
import 'text_helpers.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  ThemeData? _themeData;
  String _language = 'en'; // Default language is English

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get language => _language;
  ThemeData get themeData => _themeData ?? _buildThemeData();

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _language = prefs.getString('language') ?? 'en';
      _themeData = _buildThemeData();
      notifyListeners();
      logger.d(
          'Theme preferences loaded: isDarkMode=$_isDarkMode, fontSize=$_fontSize, language=$_language');
    } catch (e) {
      logger.e('Error loading theme preferences: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      _themeData = _buildThemeData();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      logger.d('Theme toggled: isDarkMode=$_isDarkMode');
    } catch (e) {
      logger.e('Error toggling theme: $e');
    }
  }

  Future<void> setFontSize(double size) async {
    try {
      _fontSize = size;
      _themeData = _buildThemeData();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSize', _fontSize);
      logger.d('Font size updated: fontSize=$_fontSize');
    } catch (e) {
      logger.e('Error setting font size: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      _language = language;
      _themeData = _buildThemeData();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
      logger.d('Language updated: language=$language');
    } catch (e) {
      logger.e('Error setting language: $e');
    }
  }

  // Get the appropriate font family based on current language
  String get _fontFamily {
    // Use TextHelpers to get consistent font family
    return TextHelpers.getFontFamily(_language);
  }

  ThemeData _buildThemeData() {
    return _isDarkMode ? _darkTheme() : _lightTheme();
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: _fontSize),
        bodyMedium: TextStyle(fontSize: _fontSize - 2),
        titleLarge:
            TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(fontSize: _fontSize + 2, fontWeight: FontWeight.bold),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1F1F1F),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF1F1F1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: _fontSize, color: Colors.white),
        bodyMedium: TextStyle(fontSize: _fontSize - 2, color: Colors.white70),
        titleLarge: TextStyle(
            fontSize: _fontSize + 6,
            fontWeight: FontWeight.bold,
            color: Colors.white),
        titleMedium: TextStyle(
            fontSize: _fontSize + 2,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      ),
    );
  }
}
