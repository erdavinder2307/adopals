import 'package:flutter/material.dart';
import 'theme_service.dart';

class ThemeServiceProvider extends InheritedWidget {
  final ThemeService themeService;
  final Widget child;

  ThemeServiceProvider({
    Key? key,
    required this.themeService,
    required this.child,
  }) : super(key: key, child: child);

  static ThemeServiceProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeServiceProvider>();
  }

  @override
  bool updateShouldNotify(ThemeServiceProvider oldWidget) {
    return oldWidget.themeService != themeService;
  }
}
