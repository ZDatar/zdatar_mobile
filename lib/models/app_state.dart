import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  ThemeMode _themeMode = ThemeMode.system;
  bool _developerMode = false;
  static const String _developerModeKey = 'developer_mode';

  ThemeMode get themeMode => _themeMode;
  bool get developerMode => _developerMode;

  MyAppState() {
    _loadDeveloperMode();
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    _developerMode = prefs.getBool(_developerModeKey) ?? false;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> toggleDeveloperMode() async {
    _developerMode = !_developerMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_developerModeKey, _developerMode);
    notifyListeners();
  }

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
} 