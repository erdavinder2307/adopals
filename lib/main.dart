import 'package:adopals/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'theme_service.dart';
import 'theme_service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final themeService = ThemeService();
  await themeService.loadThemeFromDB();
  runApp(ThemeServiceProvider(
    themeService: themeService,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeService? _themeService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = ThemeServiceProvider.of(context);
    if (_themeService != provider?.themeService) {
      _themeService?.removeListener(_onThemeChanged);
      _themeService = provider?.themeService;
      _themeService?.addListener(_onThemeChanged);
    }
  }

  @override
  void dispose() {
    _themeService?.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeServiceProvider.of(context)!.themeService;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adopals',
      theme: themeService.themeData,
      home: const HomeScreen(),
    );
  }
}
