import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { dark, light, amoled }

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'app_theme';

  AppTheme _theme = AppTheme.dark; // پیش‌فرض تاریک

  AppTheme get theme => _theme;
  bool get isDark => _theme != AppTheme.light;
  bool get isAmoled => _theme == AppTheme.amoled;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _theme = AppTheme.values.firstWhere((e) => e.toString() == stored);
    }
    notifyListeners();
  }

  Future<void> setTheme(AppTheme newTheme) async {
    _theme = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newTheme.toString());
    notifyListeners();
  }
}