import 'package:flutter/material.dart';

class ModernThemeService {
  static const String _defaultTheme = 'default-theme';
  
  static final Map<String, ThemeData> _themes = {
    'default-theme': _createTheme(
      primaryColor: const Color(0xFFEB8EF5),
      accentColor: const Color(0xFF8A67F5),
      isDark: false,
    ),
    'default-theme-dark': _createTheme(
      primaryColor: const Color(0xFFEB8EF5),
      accentColor: const Color(0xFF8A67F5),
      isDark: true,
    ),
    'blue-theme': _createTheme(
      primaryColor: const Color(0xFF2196F3),
      accentColor: const Color(0xFFFF4081),
      isDark: false,
    ),
    'blue-theme-dark': _createTheme(
      primaryColor: const Color(0xFF2196F3),
      accentColor: const Color(0xFFFF4081),
      isDark: true,
    ),
    'green-theme': _createTheme(
      primaryColor: const Color(0xFF4CAF50),
      accentColor: const Color(0xFFFFC107),
      isDark: false,
    ),
    'green-theme-dark': _createTheme(
      primaryColor: const Color(0xFF4CAF50),
      accentColor: const Color(0xFFFFC107),
      isDark: true,
    ),
    'red-theme': _createTheme(
      primaryColor: const Color(0xFFF44336),
      accentColor: const Color(0xFF2196F3),
      isDark: false,
    ),
    'red-theme-dark': _createTheme(
      primaryColor: const Color(0xFFF44336),
      accentColor: const Color(0xFF2196F3),
      isDark: true,
    ),
    'purple-theme': _createTheme(
      primaryColor: const Color(0xFF9C27B0),
      accentColor: const Color(0xFFCDDC39),
      isDark: false,
    ),
    'purple-theme-dark': _createTheme(
      primaryColor: const Color(0xFF9C27B0),
      accentColor: const Color(0xFFCDDC39),
      isDark: true,
    ),
    'orange-theme': _createTheme(
      primaryColor: const Color(0xFFFF9800),
      accentColor: const Color(0xFF00BCD4),
      isDark: false,
    ),
    'orange-theme-dark': _createTheme(
      primaryColor: const Color(0xFFFF9800),
      accentColor: const Color(0xFF00BCD4),
      isDark: true,
    ),
  };

  static final List<Map<String, dynamic>> availableThemes = [
    {
      'value': 'default-theme',
      'viewValue': 'Default',
      'primaryColor': '#EB8EF5',
      'accentColor': '#8A67F5',
    },
    {
      'value': 'blue-theme',
      'viewValue': 'Blue',
      'primaryColor': '#2196F3',
      'accentColor': '#FF4081',
    },
    {
      'value': 'green-theme',
      'viewValue': 'Green',
      'primaryColor': '#4CAF50',
      'accentColor': '#FFC107',
    },
    {
      'value': 'red-theme',
      'viewValue': 'Red',
      'primaryColor': '#F44336',
      'accentColor': '#2196F3',
    },
    {
      'value': 'purple-theme',
      'viewValue': 'Purple',
      'primaryColor': '#9C27B0',
      'accentColor': '#CDDC39',
    },
    {
      'value': 'orange-theme',
      'viewValue': 'Orange',
      'primaryColor': '#FF9800',
      'accentColor': '#00BCD4',
    },
  ];

  static ThemeData getTheme(String themeName) {
    return _themes[themeName] ?? _themes[_defaultTheme]!;
  }

  static bool isDarkTheme(String themeName) {
    return themeName.endsWith('-dark');
  }

  static String toggleDarkMode(String currentTheme) {
    if (isDarkTheme(currentTheme)) {
      return currentTheme.replaceAll('-dark', '');
    } else {
      return '$currentTheme-dark';
    }
  }

  static ThemeData _createTheme({
    required Color primaryColor,
    required Color accentColor,
    required bool isDark,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      secondary: accentColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.surfaceVariant;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceVariant,
        circularTrackColor: colorScheme.surfaceVariant,
      ),
    );
  }
}
