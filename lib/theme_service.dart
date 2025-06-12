import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeService extends ChangeNotifier {
  static final List<Map<String, dynamic>> themes = [
    { 'value': 'default-theme', 'viewValue': 'Default', 'primaryColor': 0xffeb8ef5, 'accentColor': 0xff8a67f5 },
    { 'value': 'blue-theme', 'viewValue': 'Blue', 'primaryColor': 0xff2196f3, 'accentColor': 0xffff4081 },
    { 'value': 'green-theme', 'viewValue': 'Green', 'primaryColor': 0xff4caf50, 'accentColor': 0xffffc107 },
    { 'value': 'red-theme', 'viewValue': 'Red', 'primaryColor': 0xfff44336, 'accentColor': 0xff2196f3 },
    { 'value': 'purple-theme', 'viewValue': 'Purple', 'primaryColor': 0xff9c27b0, 'accentColor': 0xffcddc39 },
    { 'value': 'orange-theme', 'viewValue': 'Orange', 'primaryColor': 0xffff9800, 'accentColor': 0xff00bcd4 },
  ];

  String _activeTheme = 'default-theme';
  bool get isDarkTheme => _activeTheme.endsWith('-dark');
  String get activeTheme => _activeTheme;

  ThemeData get themeData => _themeDataFor(_activeTheme);

  void setActiveTheme(String theme) async {
    _activeTheme = theme;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'theme': _activeTheme});
    }
  }

  Future<void> loadThemeFromDB() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['theme'] != null) {
        _activeTheme = data['theme'];
        notifyListeners();
      }
    }
  }

  ThemeData _themeDataFor(String theme) {
    final themeMap = themes.firstWhere((t) => t['value'] == theme.replaceAll('-dark', ''), orElse: () => themes[0]);
    final int primaryColor = themeMap['primaryColor'] as int;
    final int accentColor = themeMap['accentColor'] as int;
    final bool isDark = theme.endsWith('-dark');
    if (isDark) {
      return ThemeData.dark().copyWith(
        primaryColor: Color(primaryColor),
        colorScheme: ColorScheme.dark().copyWith(secondary: Color(accentColor)),
      );
    } else {
      return ThemeData(
        primaryColor: Color(primaryColor),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: _materialColorFrom(primaryColor)).copyWith(secondary: Color(accentColor)),
      );
    }
  }

  MaterialColor _materialColorFrom(int color) {
    final c = Color(color);
    return MaterialColor(color, <int, Color>{
      50: c.withOpacity(.1),
      100: c.withOpacity(.2),
      200: c.withOpacity(.3),
      300: c.withOpacity(.4),
      400: c.withOpacity(.5),
      500: c.withOpacity(.6),
      600: c.withOpacity(.7),
      700: c.withOpacity(.8),
      800: c.withOpacity(.9),
      900: c.withOpacity(1),
    });
  }
}
