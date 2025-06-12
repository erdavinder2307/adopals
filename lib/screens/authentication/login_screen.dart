import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../buyer_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  bool _showForgotPassword = false;
  final _forgotPasswordEmailController = TextEditingController();
  String? _forgotPasswordMessage;

  final _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _redirectIfLoggedIn();
    _loadRememberedCredentials();
  }

  void _redirectIfLoggedIn() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BuyerDashboardScreen()),
        );
      });
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final savedEmail = await _secureStorage.read(key: 'email');
    final savedPassword = await _secureStorage.read(key: 'password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
      // Optionally, auto-login:
      // _signInWithEmail();
    }
  }

  Future<void> _handleRememberMe() async {
    if (_rememberMe) {
      await _secureStorage.write(key: 'email', value: _emailController.text.trim());
      await _secureStorage.write(key: 'password', value: _passwordController.text.trim());
    } else {
      await _secureStorage.delete(key: 'email');
      await _secureStorage.delete(key: 'password');
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _handleRememberMe();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BuyerDashboardScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _handleRememberMe();
      // Navigate to home or main screen
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Navigate to home or main screen
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
        // Navigate to home or main screen
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
      _forgotPasswordMessage = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _forgotPasswordEmailController.text.trim(),
      );
      setState(() {
        _forgotPasswordMessage = 'Reset link sent! Check your email.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _forgotPasswordMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 50, 15, 150),
            child: Center(
              child: SingleChildScrollView(
                child: _showForgotPassword
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          const Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _forgotPasswordEmailController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter your email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          if (_forgotPasswordMessage != null)
                            Text(_forgotPasswordMessage!, style: TextStyle(color: _forgotPasswordMessage == 'Reset link sent! Check your email.' ? Colors.green : Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendPasswordResetEmail,
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Send Reset Link'),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _showForgotPassword = false;
                                      _forgotPasswordMessage = null;
                                    });
                                  },
                            child: const Text('Back to Login'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Image.asset('assets/images/logo-v10.png', height: 100,color: Colors.purple),
                            const SizedBox(height: 10),
                            Text(
                              _isSignUp ? "Create your Account" : "Let's dive Into your Account",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            // Email TextField
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                labelText: 'Email',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Password TextField
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                labelText: 'Password',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                suffixIcon: IconButton(
                                  icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 15),
                              // Confirm Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  labelText: 'Confirm Password',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 10),
                            // Remember me checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text("Remember me"),
                              ],
                            ),
                            if (_errorMessage != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            // Sign In/Up Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                                  backgroundColor: Colors.purple,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          if (_isSignUp) {
                                            _signUpWithEmail();
                                          } else {
                                            _signInWithEmail();
                                          }
                                        }
                                      },
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(_isSignUp ? "SIGN UP" : "SIGN IN", style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Divider
                            const Divider(color: Colors.black),
                            const SizedBox(height: 10),
                            // Google Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  backgroundColor: Colors.white,
                                ),
                                icon: const Icon(FontAwesomeIcons.google, color: Colors.red),
                                label: const Text("Continue with Google", style: TextStyle(color: Colors.black)),
                                onPressed: _isLoading ? null : _signInWithGoogle,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Facebook Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  backgroundColor: Colors.white,
                                ),
                                icon: const Icon(FontAwesomeIcons.facebook, color: Colors.blue),
                                label: const Text("Continue with Facebook", style: TextStyle(color: Colors.black)),
                                onPressed: _isLoading ? null : _signInWithFacebook,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Toggle sign in/up
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isSignUp ? "Already have an account?" : "Don't have an account?",
                                    style: const TextStyle(color: Colors.grey)),
                                TextButton(
                                  onPressed: _isLoading ? null : _toggleSignUp,
                                  child: Text(_isSignUp ? "Sign In" : "Sign Up"),
                                ),
                              ],
                            ),
                            if (!_isSignUp)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _showForgotPassword = true;
                                            _forgotPasswordEmailController.text = _emailController.text;
                                          });
                                        },
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     margin: const EdgeInsets.only(top: 0),
          //     child: const Image(
          //       image: AssetImage('assets/images/login-gradient1.png'),
          //       width: double.infinity,
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
