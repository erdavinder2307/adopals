import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 150),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset('assets/images/Adopals-v9.png', height: 70),

                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      "Create your Account",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email/Phone TextField
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        labelText: 'Email or Phone No.',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Password TextField
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        labelText: 'Password',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Confirm Password TextField
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        labelText: 'Confirm Password',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Sign Up Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 15),
                        backgroundColor: Colors.purple,
                      ),
                      onPressed: () {
                        // Handle sign up
                      },
                      child: const Text("SIGN UP",
                          style: TextStyle(color: Colors.white)),
                    ),

                    const SizedBox(height: 10),

                    // Divider
                    const Divider(color: Colors.black),

                    const SizedBox(height: 10),

                    // Google Sign Up Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(FontAwesomeIcons.google,
                          color: Colors.red),
                      label: const Text("Continue with Google",
                          style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        // Handle Google sign up
                      },
                    ),

                    const SizedBox(height: 10),

                    // Facebook Sign Up Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(FontAwesomeIcons.facebook,
                          color: Colors.blue),
                      label: const Text("Continue with Facebook",
                          style: TextStyle(color: Colors.black)),
                      onPressed: () {
                        // Handle Facebook sign up
                      },
                    ),

                    const SizedBox(height: 20),

                    // Already have an account prompt
                    const Text("Already have an account?",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.only(top: 0),
              child: const Image(
                image: AssetImage('assets/images/login-gradient.png'),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
