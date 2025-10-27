import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isInitialized = true;

      // Debug log to verify theme loading works on all platforms
      if (kDebugMode) {
        print(
          'Theme loaded from preferences (${kIsWeb ? "Web" : "Mobile"}): ${_themeMode == ThemeMode.dark ? "Dark" : "Light"}',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading theme: $e');
      }
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      await _saveThemeToPrefs();
    }
  }

  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(
        _themeKey,
        _themeMode == ThemeMode.dark,
      );

      // Debug log to verify theme saving works on all platforms
      if (kDebugMode) {
        print(
          'Theme saved to preferences (${kIsWeb ? "Web" : "Mobile"}): ${_themeMode == ThemeMode.dark ? "Dark" : "Light"} - Success: $success',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving theme: $e');
      }
    }
  }

  /// Clears the saved theme preference (useful for debugging)
  Future<void> clearThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);

      if (kDebugMode) {
        print('Theme preference cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing theme preference: $e');
      }
    }
  }
}
