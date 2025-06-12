import 'package:adopals/screens/get_started_screen.dart';
import 'package:adopals/screens/authentication/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showLogin = false;

  void _onContinue() {
    setState(() {
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return const LoginScreen();
    }
    return GetStartedScreen(onContinue: _onContinue);
  }
}
