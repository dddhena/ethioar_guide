import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static const String _themeKey = 'is_dark_mode';
  
  factory ThemeService() {
    return _instance;
  }
  
  ThemeService._internal();
  
  bool _isDarkMode = false;
  bool _initialized = false;
  
  bool get isDarkMode => _isDarkMode;
  
  Future<void> _loadThemePreference() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _initialized = true;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
  
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
  
  Future<void> initialize() async {
    await _loadThemePreference();
  }
}
