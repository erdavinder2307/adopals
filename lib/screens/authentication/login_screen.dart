import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                    Image.asset('assets/images/Adopals-v9.png',
                        height: 70), // Ensure your logo is in the assets folder

                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      "Let's dive Into your Account",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email/Phone TextField
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        labelText: 'Email/Phone No.',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Password TextField
                    TextField(
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

                    const SizedBox(height: 10),

                    // Remember me checkbox
                    Row(
                      children: [
                        Checkbox(value: false, onChanged: (value) {}),
                        const Text("Remember me"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Sign In Button
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
                        // Handle sign in
                      },
                      child: const Text("SIGN IN",
                          style: TextStyle(color: Colors.white)),
                    ),

                    const SizedBox(height: 10),

                    // Divider
                    const Divider(color: Colors.black),

                    const SizedBox(height: 10),

                    // Google Sign In Button
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
                        // Handle Google sign in
                      },
                    ),

                    const SizedBox(height: 10),

                    // Facebook Sign In Button
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
                        // Handle Facebook sign in
                      },
                    ),

                    const SizedBox(height: 20),

                    // Don't have an account prompt
                    const Text("Don't have an account?",
                        style: TextStyle(color: Colors.grey)),
                    // const Image(
                    //   image: AssetImage('assets/images/login-gradient.png'),
                    //   width: double.infinity,
                    //   fit: BoxFit.cover,
                    // ),
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
                image: AssetImage('assets/images/login-gradient1.png'),
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
