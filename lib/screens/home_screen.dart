import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'get_started_screen.dart';
import 'buyer_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, show dashboard
          return const BuyerDashboardScreen();
        } else {
          // User is not logged in, show get started screens
          return const GetStartedScreen();
        }
      },
    );
  }
}
